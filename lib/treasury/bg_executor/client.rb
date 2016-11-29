# coding: utf-8
require 'digest/sha2'

module Treasury
  module BgExecutor
    # Классс для клиентов BgExecutor
    # В инстансе мы можем:
    #   поставить задачу в очередь,
    #   спросить статус задачи,
    #   узнать информацию о задаче,
    #   спросить конечный результат
    class Client
      include Singleton

      CACHE_MUTEX = "bg_executor:cache:mutex".freeze
      SEQUENCE_KEY = "bg_executor:jobs_sequence".freeze
      QUEUE_KEY = "bg_executor:jobs_queue".freeze
      SINGLETON_JOBS_HASH_KEY = "bg_executor:singleton_jobs_hash".freeze
      JOBS_KEY_PREFIX = "bg_executor:job:".freeze

      # constructor
      def initialize
        redis.delete QUEUE_KEY unless redis.list? QUEUE_KEY
      end

      def redis
        @cache ||= BgExecutor::Redis.new
      end

      def reconnect!
        redis.redis.client.reconnect
      end

      # поставить задачу в очередь
      # возвращает два значения: ID задачи и ключ доступа к задаче
      def queue_job!(job_name, args = {})
        klass = job_class(job_name)
        singleton_hexdigest = nil

        if klass.acts_as_singleton?
          singleton_hexdigest = klass.singleton_hexdigest(args)
          is_running = singleton_job_running?(job_name, args, singleton_hexdigest)
          return is_running if is_running
        end

        args[:_critical] = true if klass.acts_as_critical?
        args.merge!(klass.default_args) if klass.default_args

        id = next_id
        raise QueueError if id.nil?
        secure = generate_secure_key

        if klass.acts_as_singleton?
          add_to_singletons(singleton_hexdigest, id: id, secure_key: secure, queued_at: Time.now.to_f)
        end

        # это для того, чтобы в логе было видно когда поставлена задача
        args[:created_at] = Time.now.to_i

        redis[job_key(id)] = {
          id: id,
          secure_key: secure,
          job_name: job_name,
          args: args,
          singleton_hexdigest: singleton_hexdigest,
          status: :new,
          info: {},
          error: nil,
          result: nil,
          queued_at: Time.now.to_f,
          started_at: nil,
          finished_at: nil,
          failed_at: nil
        }

        redis.push QUEUE_KEY, id: id,
                              job_name: job_name,
                              args: args
        if Rails.logger
          Rails.logger.info "BgExecutor queued job :name => #{job_name}, :id => #{id} :args => #{args.inspect}"
        end

        [id, secure]
      end
      alias_method :push_job!, :queue_job!

      # получить из очереди задание
      def pop
        redis.synchronize(CACHE_MUTEX) { redis.pop(QUEUE_KEY) }
      rescue => e
        puts "Error in BgExecutor::Client#pop"
        puts e.message
        puts e.backtrace.join("\n")
      end

      def singleton_job_running?(job_name, args, hexdigest = nil)
        klass = job_class(job_name)
        return unless klass.acts_as_singleton?
        hexdigest ||= klass.singleton_hexdigest(args)
        if res = redis.hget(SINGLETON_JOBS_HASH_KEY, hexdigest)
          if !klass.acts_as_no_cancel? && res[:queued_at] && (Time.now - Time.at(res[:queued_at])) > 12.hours # сборщик мусора =)
            fail_job!(res[:id], 'Job выполняется более 12 часов. Убиваем его в редисе.')
            remove_from_singletons(hexdigest) # на всякий случай сотрём инфу из хеша синглтонов, вдруг самого джоба уже не было в редисе
            return
          end
          return [res[:id], res[:secure_key]]
        end
      rescue => e
        puts "Error in BgExecutor::Client#singleton_job_running?"
        puts e.message
        puts e.backtrace.join("\n")
        return nil
      end

      def job_class(job_name)
        @_class_cache ||= {}
        @_class_cache[job_name] ||= "#{job_name}_job".classify.constantize
      end

      def job_exists?(job_id, secure_key = nil)
        exists = redis.exists?(job_key(job_id))

        raise JobAccessError if exists && secure_key.present? && !secure_key_matches?(job_id, secure_key)

        exists
      end

      # получить статус задачи
      def ask_status(job_id, secure_key = nil)
        return nil unless job_exists? job_id, secure_key

        raise JobAccessError unless secure_key_matches?(job_id, secure_key)

        (find_job(job_id) || {})[:status]
      end

      # получить информацию из задачи
      def ask_info(job_id, secure_key = nil)
        return nil unless job_exists? job_id, secure_key

        raise JobAccessError unless secure_key_matches?(job_id, secure_key)

        (find_job(job_id) || {})[:info]
      end

      # получить результат выполнения задачи
      def ask_result(job_id, secure_key = nil)
        return nil unless job_exists? job_id, secure_key

        raise JobAccessError unless secure_key_matches?(job_id, secure_key)

        j = find_job(job_id) || {}
        raise JobExecutionError, j[:error] unless j[:error].blank?

        j[:result]
      end

      # проверить ключ к задаче на зуб
      def secure_key_matches?(job_id, secure_key)
        return true if secure_key.nil?
        find_job(job_id)[:secure_key] == secure_key
      end

      # обновить информацию о задании
      def update_job!(job_id, params)
        redis[job_key job_id] = redis[job_key(job_id)].merge(params)
      rescue => e
        puts "Error in BgExecutor::Client#update_job!"
        puts e.message
      end

      def start_job!(job_id)
        update_job!(job_id, status: :running, started_at: Time.now.to_f)
      rescue => e
        puts "Error in BgExecutor::Client#start_job!"
        puts e.message
      end

      # считать задание завершенным
      def finish_job!(job_id)
        if (job = find_job(job_id))
          remove_from_singletons(job[:singleton_hexdigest]) if job[:singleton_hexdigest]

          job_updates = {:status => :finished, :finished_at => Time.now.to_f}
          if job[:started_at].present?
            job_updates[:info] = job[:info].merge(:execution_time => "%.2f" % [Time.now.to_f - job[:started_at]])
          end
          update_job!(job_id, job_updates)
        end
        redis.expire(job_key(job_id), 600)
      rescue => e
        puts "Error in BgExecutor::Client#finish_job!"
        puts e.message
      end

      # считать задание проваленным
      def fail_job!(job_id, exception)
        if exception.is_a?(::Exception)
          error = [exception.message, exception.backtrace.present? ? exception.backtrace.join("\n") : ''].join("\n")
        else
          error = exception.to_s
        end

        if (job = find_job(job_id))
          remove_from_singletons(job[:singleton_hexdigest]) if job[:singleton_hexdigest]

          job_updates = {:status => :failed, :error => error, :failed_at => Time.now.to_f}
          if job[:started_at].present?
            job_updates[:info] = job[:info].merge(:execution_time => "%.2f" % [Time.now.to_f - job[:started_at]])
          end
          update_job!(job_id, job_updates)
        end
        redis.expire(job_key(job_id), 600)
      rescue => e
        puts "Error in BgExecutor::Client#fail_job!"
        puts e.message
      end

      def reset!
        redis.synchronize(CACHE_MUTEX) do
          redis.zero(SEQUENCE_KEY)
          redis.delete(QUEUE_KEY)
          redis.delete(SINGLETON_JOBS_HASH_KEY)
        end
      end

      def find_job(id)
        redis[job_key(id)]
      end

      protected

      def next_id
        redis.increment(SEQUENCE_KEY)
      end

      def job_key(id)
        "#{JOBS_KEY_PREFIX}#{id}"
      end

      def add_to_singletons(hexdigest, args)
        redis.hset SINGLETON_JOBS_HASH_KEY, hexdigest, args
      end

      def remove_from_singletons(hexdigest)
        redis.hdel SINGLETON_JOBS_HASH_KEY, hexdigest
      end

      def generate_secure_key
        Digest::SHA2.hexdigest(rand.to_s)
      end
    end
  end
end
