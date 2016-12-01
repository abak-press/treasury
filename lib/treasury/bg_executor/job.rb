# coding: utf-8
require 'digest/sha2'

module Treasury
  module BgExecutor
    class Job
      class_attribute :singleton_job, :critical_job, :no_trace_job, :no_cancel_job, :default_args

      attr_reader :id, :result, :info, :params

      class << self
        def create(id, job_name, params)
          "#{job_name}_job".classify.constantize.new(id, params)
        end

        # указать, что только один джоб этого класса может выполняться в одну единицу времени
        # можно также задать указать параметры джоба, и тогда только один джоб с такой комбинацией параметров может выполняться в одну единицу времени
        def acts_as_singleton(scope = [])
          self.singleton_job = Array(scope)
        end

        def acts_as_singleton?
          !singleton_job.nil?
        end

        def singleton_scope
          singleton_job
        end

        def singleton_hexdigest(args)
          result = nil
          if acts_as_singleton?
            singleton_args = args.select { |k, _| singleton_scope.include?(k) }
            result = Digest::SHA2.hexdigest(name + singleton_args.sort.to_hash.to_s)
          end

          result
        end

        def add_default_args(args)
          self.default_args ||= {}
          self.default_args.merge!(args)
        end

        # указать, что джоб важный, и в случае его падения, ставить его опять в очередь.
        # Количество попыток ограничено в конфиге опцией max_tries_on_fail, по умолчанию Daemon:DEFAULT_MAX_TRIES_ON_FAIL
        def acts_as_critical(job_args = {})
          self.critical_job = true
          add_default_args(job_args) if job_args.present?
        end

        def acts_as_critical?
          !!critical_job
        end

        # указать, что не нужно вести трассировку сессии для NewRelic
        def acts_as_no_cancel
          self.no_cancel_job = true
        end

        def acts_as_no_cancel?
          !!no_cancel_job
        end
      end

      def initialize(id, params)
        @id = id
        raise "No such job in queue" unless params[:allow_new] || client.job_exists?(@id)

        @info = {}
        @result = nil
        @error  = nil

        @params = params
      end

      def result=(value)
        @result = value
        client.update_job!(id, result: @result)
      end

      def info=(value)
        @info = value
        client.update_job!(id, info: @info)
      end

      def execute
        # override in descendants
      end

      def title
        @params[:_job_title] || @params[:job_name]
      end

      private

      def client
        @client ||= BgExecutor::Client.instance
      end
    end

    # класс для джобов, которые можно проецировать в прогресс-бар
    class Job::Indicated < Job
      attr_reader :completed

      def initialize(id, params)
        super id, params
        self.info = {:completed => 0.0}
        @total = 1
        @completed = 0
      end

      # указать, сколько всего итемов в джобе
      def total=(total_items)
        raise ArgumentError unless total_items.is_a?(Integer)
        @total = total_items
      end

      # указать, сколько итемов в джобе завершено
      def completed=(completed_items)
        raise ArgumentError unless completed_items.is_a?(Integer)
        @completed = completed_items
        update_percentage!
      end

      def message=(value)
        self.info = info.merge(message: value)
      end

      def redirect_url=(value)
        self.info = info.merge(redirect_url: value)
      end

      def increment_completed!(count = nil)
        self.completed = @completed + (count || 1)
      end

      def update_percentage!
        self.info = info.merge(completed: ((@completed.to_f / [@total, 1].max.to_f) * 100).round)
      end
    end

    class CallMethodJob < Job
      acts_as_singleton [:object, :method]

      def execute
        object = Marshal.load(Base64.decode64(params[:object]))

        if params[:method_args].present?
          object.send params[:method], *params[:method_args]
        else
          object.send params[:method]
        end
      end
    end
  end
end
