module Treasury
  # Public: обеспечивает блокировку ресурса на бесконечный срок
  #
  # Examples
  #   ::Treasury::Lock.with_lock(:worker_1) do
  #     Worker.process
  #   end
  class Lock
    KEY = 'treasury:locks'.freeze

    def initialize(object)
      @object = (object.is_a?(::String) || object.is_a?(::Symbol)) ? object : object.id.to_s
    end

    class << self
      def with_lock(object, &block)
        new(object).with_lock(&block)
      end
    end

    def lock
      redis.sadd(KEY, @object)
    end

    def lock!
      raise "failed to acqure lock #{@object}" if locked?

      lock
    end

    def unlock
      redis.srem(KEY, @object)
    end

    def locked?
      redis.sismember(KEY, @object)
    end

    def with_lock(&block)
      if lock!
        begin
          @result = yield
        ensure
          unlock
        end
      end
      @result
    end

    private

    def redis
      ::Treasury.configuration.redis
    end
  end
end
