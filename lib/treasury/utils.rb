module Treasury
  module Utils
    extend ActiveSupport::Concern

    PROJECT_ROOT_PATH = Regexp.new(Rails.root.to_s)
    OWN_GEMS_PATH = Regexp.new("apress|treasury")

    included do
      attr_reader :process_object
    end

    module ClassMethods
      def connection
        ActiveRecord::Base.connection
      end

      def quote(value)
        ActiveRecord::Base.connection.quote(value)
      end

      def log_error(exception)
        backtrace = exception.backtrace.select { |line| line =~ PROJECT_ROOT_PATH || line =~ OWN_GEMS_PATH }
        error_message = "#{exception.message}\n\n #{backtrace.join("\n")}"
        logger.error error_message
        error_message
      rescue
        nil
      end

      def current_method_name
        if  /`(.*)'/.match(caller.first)
          return $1
        end
        nil
      end
    end

    def connection
      self.class.connection
    end

    def quote(value)
      self.class.quote(value)
    end

    def log_error(exception)
      save_error(self.class.log_error(exception))
    rescue
    end

    def check_terminate
      refresh_state
      return true unless @process_object.need_terminate?
      logger.warn "Принят сигнал на завершение работы"
      @process_object.need_terminate = false
      @process_object.save!
      false
    end

    def check_state(state)
      @process_object.state == state
    end

    def set_state(state)
      return set_session if check_state(state) && process_is_alive?(@process_object.pid)

      @process_object.state = state

      if state == 'stopped'
        reset_session
      else
        set_session
      end

      logger.info "Установлен статус %s" % [quote(@process_object.state)]
    end

    def set_session
      @process_object.pid = pid
      @process_object.save!
      logger.info "Установлен PID %s" % [quote(@process_object.pid)]
    end

    def reset_session
      @process_object.pid = nil
      @process_object.save!

      logger.info 'PID сброшен'
    end

    def save_error(error_message)
      error_message = error_message[1, 4000] unless error_message.nil?
      @process_object.last_error = error_message
      @process_object.save!
    end

    def clear_last_error
      save_error(nil)
    end

    def current_method_name
      self.class.current_method_name
    end

    def refresh_state
      @process_object.reload
    end
  end
end
