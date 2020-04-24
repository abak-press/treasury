module Treasury
  module Storage
    module Redis
      # базовый класс хранилища на основе Redis
      # из-за особеностей реализации транзакционности в Redis,
      # а именно невозможности чтения данных, пока выполняется транзакция,
      # используется 2 соединения с Redis - для чтения и записи
      class Base < Treasury::Storage::Base
        RESET_FIELDS_BATCH_SIZE = 1000
        RESET_FIELDS_BATCH_PAUSE = Rails.env.staging? || !Rails.env.production? ? 0.seconds : 0.seconds

        CURSOR_STOP_FLAG = '0'.freeze
        private_constant :CURSOR_STOP_FLAG

        self.default_reset_strategy = :delete

        def transaction_bulk_write(data)
          write_session.pipelined do
            start_transaction
            data.each { |object, value| internal_write(object, value) }
            fire_callback(:after_transaction_bulk_write, self)
            commit_transaction
          end
        end

        def bulk_write(data)
          write_session.pipelined do
            data.each { |object, value| internal_write(object, value) }
          end
        end

        def reset_data(objects, fields)
          reset_fields(fields)
        end

        def start_transaction
          return if transaction_started?
          write_session.multi
          super
        end

        def commit_transaction
          return unless transaction_started?
          write_session.exec
          super
        end

        def rollback_transaction
          return unless transaction_started?
          write_session.discard
          super
        end

        def use_own_connection?
          true
        end

        protected

        def read_session
          Treasury.configuration.redis
        end

        def write_session
          @@write_session ||= self.class.new_redis_session
        end

        def hset(object, field, value)
          write_session.hset(key(object), @params[:fields_prefix] ? prepare_field(field) : field, value)
        end

        def hget(object, field)
          read_session.hget(key(object), @params[:fields_prefix] ? prepare_field(field) : field)
        end

        def hdel(object, field)
          write_session.hdel(key(object), @params[:fields_prefix] ? prepare_field(field) : field)
        end

        def delete(object)
          write_session.del(key(object))
        end

        def expire(object, timeout)
          write_session.expire(key(object), timeout)
        end

        def reset_hash_fields(hash_key, fields)
          fields = fields.map { |field| @params[:fields_prefix] ? prepare_field(field) : field }
          cursor = 0

          loop do
            cursor, keys = read_session.scan(cursor, match: hash_key, count: RESET_FIELDS_BATCH_SIZE)

            write_session.pipelined do
              keys.each { |key| write_session.hdel(key, fields) }
            end

            break if cursor == CURSOR_STOP_FLAG

            sleep(RESET_FIELDS_BATCH_PAUSE)
          end
        end

        def object_key
          @object_key ||= "#{Treasury::ROOT_REDIS_KEY}:#{params[:key]}"
        end

        def key(object)
          "#{object_key}:#{object}"
        end

        def reset_fields(fields)
          reset_hash_fields("#{object_key}*", fields)
        end

        def internal_write(object, data)
          data.present? ? write(object, data) : delete(object)
        end

        def self.new_redis_session
          client = if Gem::Version.new(::Redis::VERSION) < Gem::Version.new('4')
                     Treasury.configuration.redis.client
                   else
                     Treasury.configuration.redis._client
                   end

          ::Redis.new(client.options)
        end

        module Batch
          PROCESSED_BATCHES_KEY = "#{Treasury::ROOT_REDIS_KEY}:processed_batches".freeze
          PROCESSED_BATCHES_EXPIRE_AFTER = 3.days

          def add_batch_to_processed_list(batch_id)
            key = processed_batch_key(batch_id)
            write_session.set(key, nil)
            write_session.expire(key, PROCESSED_BATCHES_EXPIRE_AFTER)
          end

          def batch_already_processed?(batch_id)
            read_session.exists(processed_batch_key(batch_id))
          end

          protected

          def processed_batch_key(batch_id)
            namespace = source_id
            namespace = "#{namespace}:" if namespace.present?

            "#{PROCESSED_BATCHES_KEY}:#{namespace}#{batch_id}"
          end
        end

        include Batch
      end
    end
  end
end
