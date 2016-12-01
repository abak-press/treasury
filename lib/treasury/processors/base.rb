# coding: utf-8

module Treasury
  module Processors
    class Base < Treasury::Pgq::Consumer
      DEFAULT_FETCH_SIZE = 5000

      attr_reader   :logger
      attr_reader   :processor_info
      attr_reader   :consumer_name
      attr_reader   :queue_name
      attr_reader   :data
      attr_reader   :params
      attr_reader   :event
      attr_accessor :object

      def initialize(processor_info, logger = Rails.logger)
        @processor_info = processor_info
        @logger = logger
        @event = Treasury::Pgq::Event.new(nil)
        @snapshot = Treasury::Pgq::Snapshot.new(field.field_model.snapshot_id)
        @cursor_name = "denorm_proc_#{processor_info.id}"

        init_params
        super(@queue_name, @consumer_name, work_connection)
      end

      def process
        events_processed = 0
        rows_written = 0
        @changed_keys = []

        get_batch
        return {:events_processed => 0, :rows_written => 0} unless @batch_id

        init_storage

        main_connection.transaction do
          work_connection.transaction do
            before_batch_processing

            start_storage_transaction

            reset_buffer

            get_batch_events do |events|
              process_events_batch(events)
              events_processed += events.size
            end

            write_data

            rows_written = @data.size
            @changed_keys = @data.keys

            after_batch_processing

            commit_storage_transaction

            finish_batch
          end
        end

        data_changed

        {:events_processed => events_processed, :rows_written => rows_written}
      rescue StandardError, NotImplementedError
        rollback_storage_transaction
        raise
      end

      def current_value(field_name = nil)
        object_value(@object, field_name)
      end

      def object_value(l_object, field_name = nil)
        value = if @data.key?(l_object) && @data[l_object].key?(field_name || field.first_field)
                  @data[l_object][field_name || field.first_field]
                else
                  field.raw_value(l_object, field_name)
                end
        log_event(:message => "get object #{l_object} value", :payload => value)
        value
      end

      def form_value(value)
        value
      end

      def result_row(value)
        {@object => form_value(value)}
      end

      def no_action
        nil
      end

      protected

      def init_params
        @params        = @processor_info.params || HashWithIndifferentAccess.new
        @queue_name    = @processor_info.queue.pgq_queue_name
        @consumer_name = @processor_info.consumer_name
        @fetch_size    = DEFAULT_FETCH_SIZE
      end

      def init_event_params
        @object = @event.raw_data[:id]
      end

      def process_event
        case @event.type
        when Pgq::Event::TYPE_INSERT
          process_insert
        when Pgq::Event::TYPE_UPDATE
          process_update if @event.data_changed?
        when Pgq::Event::TYPE_DELETE
          process_delete
        else
          raise Errors::UnknownEventTypeError
        end
      end

      def process_insert
        raise NotImplementedError
      end

      def process_update
        raise NotImplementedError
      end

      def process_delete
        raise NotImplementedError
      end

      def after_process_event
      end

      def current_value_as_integer(field_name = nil)
        current_value(field_name).to_i
      end

      def incremented_current_value(field_name = nil, by = 1)
        current_value_as_integer(field_name) + by
      end

      def decremented_current_value(field_name = nil, by = 1)
        current_value_as_integer(field_name) - by
      end

      # Protected: Зануляет поля расчитываемые обработчиком.
      #
      # Returns Hash.
      #
      def nullify_current_value
        result_row(nil)
      end

      # Protected: Помечает строку для удаления.
      #
      # Returns Hash.
      #
      def delete_current_row
        {@object => nil}
      end

      # Protected: Удаляет поля расчитываемые обработчиком.
      #
      # В зависимости от того является ли обработчик ведущим, либо удаляет
      # строку из хранилища, либо зануляет значение.
      #
      # Returns Hash.
      #
      def delete_current_value
        master? ? delete_current_row : nullify_current_value
      end

      # Protected: Возвращает признак - является ли обработчик, ведущим.
      #
      # Returns Boolean.
      #
      def master?
        params.fetch(:master, false)
      end

      # колбеки, для перекрытия в наследниках

      def before_batch_processing; end

      def after_batch_processing; end

      def field
        @field ||= Treasury::Fields::Base.create_by_class(field_class, processor_info.field)
      end

      # Protected: Отложить событие в очередь на последующую обработку.
      #
      # Returns no_action.
      #
      def event_retry(retry_seconds)
        super(@event.id, retry_seconds)
        logger.warn "Событие отложено! (#{@event.inspect})"
        no_action
      end

      # Protected: Регистрирует событие в журнале.
      #
      # Returns no_action.
      #
      def log_event(params)
        params = {
          :consumer => consumer_name,
          :event => @event
        }.merge!(params)

        Treasury::Services::EventsLogger.add(params)
      end

      # Protected: Рабочее соединение с БД для данной очереди.
      #
      # В рамках этого соединения производится обработка событий конкретного процессора.
      #
      # Returns ActiveRecord::ConnectionAdapters::AbstractAdapter.
      #
      def work_connection
        @work_connection ||= processor_info.queue.work_connection
      end

      # Protected: Основное соединение с БД.
      #
      # В рамках этого соединения производятся общие действия (изменения метаданных).
      #
      # Returns ActiveRecord::ConnectionAdapters::AbstractAdapter.
      #
      def main_connection
        ActiveRecord::Base.connection
      end

      # Protected: Возвращает идентификатор источника событий (по сути уникальный идентификатор БД)
      #
      # Returns String.
      #
      def source_id
        Digest::MD5.hexdigest(db_link_class) if db_link_class.present?
      end

      def db_link_class
        @db_link_class ||= processor_info.queue.db_link_class
      end

      private

      def interesting_event?
        # фильтруем события, которые были поставлены в очередь,
        # но были видны и обработаны при иницилизации
        # TODO: подумать как не фильтровать все время, в лондисте есть механизм, я видел
        !@snapshot.contains?(@event.txid)
      end

      def write_data
        return if @data.empty?
        storages.each do |storage|
          storage.bulk_write(@data)
        end
      end

      def start_storage_transaction
        storages.each(&:start_transaction)
      end

      def commit_storage_transaction
        storages.each do |storage|
          storage.add_batch_to_processed_list(@batch_id)
          storage.commit_transaction
        end
      end

      def rollback_storage_transaction
        storages.each(&:rollback_transaction)
      end

      def reset_buffer
        @data = HashWithIndifferentAccess.new
      end

      def field_class
        @field_class ||= @processor_info.field.field_class
      end

      # Internal: метод возврашающий хранилища используемые данным процессором, кешируется
      #           Важно! Если при определении процессора указан массив :params => {..., :storage_ids => [...]}
      #           данный процессор будет работать только с указанными по ID хранилищами.
      #
      # Returns Array of Storage
      def storages
        @storages ||= if @params.key?(:storage_ids)
                        field.storages_by_ids(@params[:storage_ids])
                      else
                        field.storages
                      end
      end

      def get_batch
        @batch_id = get_next_batch
      end

      def process_events_batch(events)
        # logger.debug "Событий в батче: #{events.size}" if events.size > 0
        events.each { |ev| internal_process_event(ev) }
      end

      def internal_process_event(ev)
        # @logger.info "event: #{ev.inspect}"
        @event.assign(ev)
        log_event(:message => 'input')

        unless interesting_event?
          log_event(:message => 'not interesting. passed.', :payload => @snapshot.as_string)
          return
        end

        init_event_params
        result = process_event

        log_event(:message => 'processing result', :payload => result)
        @data.deep_merge!(result) if result.present?
        after_process_event
        # @logger.info "result_row: #{result.inspect}" if result.present?
      end

      def get_batch_events
        events = get_batch_events_by_cursor(@batch_id, @cursor_name, @fetch_size)

        return events if events.empty?

        if batch_already_processed?
          log_event(:message => 'batch already processed', :payload => @batch_id)
          logger.warn "Батч #{@batch_id} уже был ранее обработан! События пропущены."
          return []
        end

        yield events

        options = {
          name: @cursor_name,
          connection: work_connection,
          fetch_size: @fetch_size
        }

        PgTools::Cursor.each_batch(options) { |events| yield events }
      end

      # метод проверяет целостность данных в хранилищах
      # обеспечивает защиту от повторного выполнения батча
      # при нарушение целостности данных, генерирует исключение
      # нарушение целостности данных возможно когда используется больше одного хранилища,
      # если в одно хранилище данные были записаны, а в другое нет
      # return boolean
      # true  - батч уже был ранее обработан и должен быть пропущен
      # false - батч, не был ранее обработан и должен быть обработан
      def batch_already_processed?
        return false if storages.blank?

        # проверяем тип первого (основного хранилища)
        if storages.first.use_own_connection?
          # если используется своя сессия, проверяем обработан ли батч
          # если нет, выходим, ведем обычную обработку
          return if storages.first.batch_no_processed?(@batch_id)
          # если обработан, то выбираем хранилища использующие свою сессию и не обработавшие батч
          # использующие основную сессию
          bad_storages  = storages.select { |s| s.use_own_connection? && s.batch_no_processed?(@batch_id) }
          bad_storages += storages.select(&:use_processor_connection?)
          # если таких, нет, то батч считается обработаннм и пропускается
          return true if bad_storages.blank?
          # если есть, то требуется переиницилизация поля
        else
          # если используется основная сессия, то:
          # проверяем, есть ли хранилища, со своей сессией, где обработан батч
          # если нет, выходим, ведем обычную обработку
          return unless storages.any? { |s| s.use_own_connection? && s.batch_already_processed?(@batch_id) }
          # если есть, то требуется переиницилизация поля
        end

        raise Errors::InconsistencyDataError
      end

      def data_changed
        return unless @changed_keys.present?
        field.send(:data_changed, @changed_keys)
      rescue => e
        logger.error "Ошибка при вызове колбека data_changed:"
        logger.error "#{e.message}\n\n #{e.backtrace.join("\n")}"
      end

      def init_storage
        storages.each { |storage| storage.source = self }
      end
    end
  end
end
