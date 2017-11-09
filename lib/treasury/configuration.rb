module Treasury
  class Configuration
    attr_accessor :redis,
                  :bge_concurrency,
                  :bge_max_tries_on_fail,
                  :bge_namespace,
                  :bge_queue_timeout,
                  :bge_daemon_options,
                  :job_error_notifications,
                  :events_loggers

    def initialize
      self.bge_concurrency = 4
      self.bge_queue_timeout = 300
      self.bge_max_tries_on_fail = 5
      self.events_loggers = ['Treasury::Services::EventsLogger']
    end
  end
end
