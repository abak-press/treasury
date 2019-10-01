module Treasury
  module Storage
    module PostgreSQL
      # Хранилище, пишущее данные в очередь Pgq.
      #
      # Добавляет в очередь с именем queue, события типа EVENT_TYPE.
      # Данные передаются в виде url-encoded строки: "key=_processor_id_=processor_class&object&field=value&..."
      # _processor_id_ - имя класса процессора, источника данных.
      #
      # параметры:
      #   :queue => queue_name - имя очереди
      #   :key   => column     - ключевое поле
      #   :db_link_class => model_class - класс соединения с БД (опционально)
      #
      # События удаления игнорируются.
      #
      class PgqProducer < Treasury::Storage::Base
        include Treasury::Storage::PostgreSQL::Base

        DEFAULT_ID = :pgq
        EVENT_TYPE = Pgq::Event::TYPE_INSERT

        def transaction_bulk_write(data)
          transaction { bulk_write(data) }
          fire_callback(:after_transaction_bulk_write, self)
        end

        def bulk_write(data)
          data.each { |object, row| write(object, row) }
        end

        def reset_data(objects, fields)
        end

        protected

        def default_id
          DEFAULT_ID
        end

        def queue
          @queue ||= params[:queue]
        end

        def event_type
          @event_type ||= "#{EVENT_TYPE}:id"
        end

        def key
          params[:key]
        end

        # Protected: Добавляет событие в очередь PGQ.
        #
        # Returns nothing.
        #
        def write(object, row)
          return if row.nil?

          prepared_row = {key => object, :_processor_id_ => source.class.name}
          prepared_row.merge!(row.inject(Hash.new) { |result, (field, value)| result.merge!(prepare_field(field) => value) })
          data = Rack::Utils.build_query(prepared_row)
          ActiveRecord::Base.pgq_insert_event(queue, event_type, data)
        end
      end
    end
  end
end
