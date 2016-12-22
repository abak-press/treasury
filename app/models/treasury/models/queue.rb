# coding: utf-8
module Treasury
  module Models
    class Queue < ActiveRecord::Base
      self.table_name = 'denormalization.queues'
      self.primary_key = 'id'

      TRIGGER_PREFIX = 'tr_denorm'.freeze

      has_many :processors, :class_name => 'Treasury::Models::Processor', :dependent => :destroy

      before_destroy :destroy_pgq_queue
      after_create :create_pgq_queue
      # + пересоздавать очередь и триггер при изменениях

      def self.generate_trigger(options = {})
        options = {:backup => true}.merge(options)

        raise ArgumentError if options[:ignore] && options[:include]
        raise ArgumentError, ':table_name is required' if options[:include] && !options[:table_name]

        events = options[:events] && ([*options[:events]] & [:insert, :update, :delete])
        events = [:insert, :update, :delete] if events.nil?
        raise ArgumentError, ':events should include :insert, :update or :delete' if events && events.empty?

        if options[:include].present?
          connection = options.fetch(:connection, ActiveRecord::Base.connection)

          all_table_columns = connection.columns(options[:table_name]).map(&:name)
          included_table_columns = options[:include].split(',').map(&:strip).uniq.compact
          ignore_list = (all_table_columns - included_table_columns).join(',')
        elsif options[:ignore].present?
          ignore_list = options[:ignore]
        end

        conditions = nil
        conditions = "WHEN (#{options[:conditions]})" if options.key?(:conditions)

        params = ''
        params << ", 'backup'" if options[:backup]
        params << ", #{quote("ignore=#{ignore_list}")}" if ignore_list.present?
        params << ", #{quote("pkey=#{Array.wrap(options[:pkey]).join(',')}")}" if options[:pkey].present?

        of_columns = "OF #{options[:of_columns].join(',')}" if options[:of_columns]

        <<-SQL
          CREATE TRIGGER %{trigger_name}
            AFTER #{events.join(' OR ')}
            #{of_columns}
            ON %{table_name}
            FOR EACH ROW
            #{conditions}
            EXECUTE PROCEDURE pgq.logutriga(%{queue_name}#{params});
        SQL
      end

      def generate_trigger(options = {})
        options = {
          table_name: table_name,
          connection: work_connection
        }.merge(options)

        self.class.generate_trigger(options)
      end

      def create_pgq_queue
        work_connection.transaction do
          result = self.class.pgq_create_queue(pgq_queue_name, work_connection)
          raise "Queue already exists! #{pgq_queue_name}" if result == 0
          recreate_trigger(false)
        end
      end

      def destroy_pgq_queue
        work_connection.transaction do
          processors.each(&:unregister_consumer)
          pgq_drop_queue
          drop_pgq_trigger
        end
      end

      def recreate_trigger(lock_table = true)
        return unless table_name.present?

        work_connection.transaction do
          self.lock_table! if lock_table
          drop_pgq_trigger
          create_pgq_trigger
        end
      end

      def pgq_queue_exists?
        self.class.pgq_get_queue_info(pgq_queue_name, work_connection).present?
      end

      # Public: Рабочее соединение с БД для данной очереди.
      #
      # В рамках этого соединения производятся все действия с объектами привязанными к данной очереди,
      # а именно инициализация и обработка событий.
      #
      # db_link_class - Имя класса - модели ActiveRecord, обеспечивающая связь с БД.
      #
      # Returns ActiveRecord::ConnectionAdapters::AbstractAdapter.
      #
      def work_connection
        return main_connection if db_link_class.nil?

        db_link_class.constantize.connection
      end

      # Public: Основное соединение с БД.
      #
      # В рамках этого соединения производятся общие действия (изменения метаданных).
      #
      # Returns ActiveRecord::ConnectionAdapters::AbstractAdapter.
      #
      def main_connection
        ActiveRecord::Base.connection
      end

      def pgq_queue_name
        "q_#{name}"
      end

      protected

      def lock_table!
        work_connection.execute <<-SQL
          LOCK TABLE #{table_name} IN SHARE MODE
        SQL
      end

      def create_pgq_trigger(options = {})
        default_options = {
          trigger_code: trigger_code || generate_trigger(options),
          trigger_name: trigger_name,
          table_name: table_name,
          queue_name: pgq_queue_name
        }

        options.reverse_merge!(default_options)
        options[:queue_name] = quote(options[:queue_name])

        work_connection.execute options[:trigger_code] % options
      end

      def drop_pgq_trigger
        return unless table_name.present?

        work_connection.execute <<-SQL
          DROP TRIGGER IF EXISTS #{trigger_name} ON #{table_name}
        SQL
      end

      def pgq_drop_queue
        return unless self.class.pgq_queue_exists?(pgq_queue_name, work_connection)
        self.class.pgq_drop_queue(pgq_queue_name, work_connection)
      end

      def trigger_name
        # cut scheme name
        clear_name = name.split('.').last
        "#{TRIGGER_PREFIX}_#{clear_name}"
      end

      def quote(text)
        self.class.quote(text)
      end

      def self.quote(text)
        ActiveRecord::Base.connection.quote(text)
      end
    end
  end
end
