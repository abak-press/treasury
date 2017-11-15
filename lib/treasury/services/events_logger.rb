# coding: utf-8
require 'class_logger'

module Treasury
  module Services
    # Логгер обрабатываемых событий.
    # Позволяет отлаживать обработчики в тех случаях, когда данные считаются не верно.
    # Пишет в Redis. Умеет выгружать в БД.
    #
    class EventsLogger
      include ::ClassLogger

      LOGGER_FILE_NAME = "#{ROOT_LOGGER_DIR}/events_logger".freeze
      INROW_DELIMITER = '{{!cslirs!}}'.freeze
      INROW_EMPTY = 'nil'.freeze
      ROWS_PER_LOOP = 5000

      attr_accessor :params

      def self.add(params)
        @instance ||= self.new
        @instance.params = params
        @instance.add
      end

      def add
        return unless need_logging?

        time = Time.now.utc
        key = events_list_key(time.to_date)
        value = [
          time,
          params[:consumer],
          params[:event].id,
          params[:event].type,
          params[:event].birth_time,
          params[:event].txid,
          params[:event].ev_data,
          params[:event].extra1,
          params[:event].data,
          params[:event].prev_data,
          params[:event].data_changed?.to_s,
          params[:message] || INROW_EMPTY,
          params[:payload].inspect || INROW_EMPTY,
          suspected_event?.to_s
        ].join(INROW_DELIMITER)

        redis.rpush(key, value)
        redis.sadd(dates_set_key, key)

        logger.fatal(value) if suspected_event?
      end

      def process(date, clear_table = false, delete_from_redis = true)
        raise ':date param is not a date/time' unless date.is_a?(Date) || date.is_a?(Time)

        key = events_list_key(date)
        unless redis.exists(key)
          logger.warn("Log rows for date [#{date}] not found")
          return
        end

        rows_count = redis.llen(key).to_i
        logger.info("[#{rows_count}] rows found for date [#{date}]")
        return if rows_count.zero?

        processed = 0
        model_class.transaction do
          offset = 0
          limit  = ROWS_PER_LOOP

          model_class.clear(date) if clear_table
          while rows = redis.lrange(key, offset, offset + limit - 1)
            processed_rows = {:rows => []}
            for row in rows do
              processed_row = process_row(row)
              processed_rows[:fields] ||= processed_row.keys
              processed_rows[:rows] << quote(processed_row.values).join(', ')
            end

            insert_into_table(processed_rows[:fields], processed_rows[:rows])
            processed += processed_rows[:rows].size

            logger.info("[#{processed}/#{rows_count}] rows processed for date [#{date}]")
            break if rows.length < limit
            offset += limit
          end
        end

        delete_events(date) if delete_from_redis
      rescue => e
        logger.fatal "#{e.message}\n\n #{e.backtrace.join("\n")}"
        ErrorMailer.custom_error(text: "Ошибка при переносе лога обработанных событий Treasury::EventsLogger!",
                                 message: e.inspect,
                                 backtrace: e.backtrace).deliver
        raise
      end

      def delete_events(date)
        raise ':date param is not a date/time' if !date.is_a?(Date) && !date.is_a?(Time)

        key = events_list_key(date)
        logger.info("Removing events key [#{key}] from Redis")
        logger.error("Redis key [#{key}] remove fail") unless redis.del(key)
        logger.info("Removing member [#{key}] of set [#{dates_set_key}] from Redis")
        logger.error("Redis member [#{key}] of set [#{dates_set_key}] remove fail") unless redis.srem(dates_set_key, key)
      end

      def dates_list
        result = {}
        dates  = redis.smembers(dates_set_key)
        return result if dates.blank?
        dates.each do |date_key|
          if redis.exists(date_key)
            result[date_key] = redis.llen(date_key).to_i
          else
            result[date_key] = 'not exists'
          end
        end
        result
      end

      protected

      def need_logging?
        false
      end

      def suspected_event?
        false
      end

      def events_list_key(date)
        "#{root_key}:eventslog:#{date.strftime('%Y:%m:%d')}"
      end

      def dates_set_key
        "#{root_key}:eventslog:dates:list"
      end

      def root_key
        "#{Treasury::ROOT_REDIS_KEY}"
      end

      def redis
        Treasury.configuration.redis
      end

      def process_row(row)
        data = row.split(INROW_DELIMITER)
        data.map! { |value| value.strip.eql?(INROW_EMPTY) ? nil : value }

        {
          processed_at:       data[0],
          consumer:           data[1],
          event_id:           data[2],
          event_type:         data[3],
          event_time:         data[4],
          event_txid:         data[5],
          event_ev_data:      data[6],
          event_extra1:       data[7],
          event_data:         data[8],
          event_prev_data:    data[9],
          event_data_changed: data[10].to_b,
          message:            data[11],
          payload:            data[12],
          suspected:          data[13].to_b
        }
      end

      def insert_into_table(fields, data)
        connection.execute(<<-SQL)
          INSERT INTO #{model_class.quoted_table_name}
          (#{fields.join(', ')})
          VALUES
          (#{data.join('),(')});
        SQL
      end

      def quote(data)
        return data unless data.is_a?(Array)
        data.map { |value| connection.quote(value) }
      end

      def connection
        model_class.connection
      end

      def model_class
        Treasury::Models::EventsLog
      end

      def self.logger_default_file_name
        LOGGER_FILE_NAME
      end

      ActiveSupport.run_load_hooks(:'treasury/services/events_logger', self)
    end
  end
end
