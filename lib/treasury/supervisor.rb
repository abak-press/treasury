module Treasury
  class Supervisor
    STATE_RUNNING = 'running'.freeze
    STATE_STOPPED = 'stopped'.freeze

    PROCESS_LOOP_SLEEP_TIME = 2.second
    MAX_INITIALIZERS = 1

    LOGGER_FILE_NAME = "#{ROOT_LOGGER_DIR}/supervisor".freeze

    module Errors
      class SupervisorError < StandardError; end
    end

    def self.run
      supervisor = Models::SupervisorStatus.first
      self.new(supervisor).process
    end

    def process
      logger.warn "Supervisor запущен"
      begin
        return unless check_active
        set_state(STATE_RUNNING)
        clear_last_error
        while true
          break unless check_terminate
          run_initializers
          run_workers
          sleep(PROCESS_LOOP_SLEEP_TIME)
        end
      rescue => e
        log_error(e)
        raise
        # TODO: нужно убрать райз и сделать свою отправку ошибки, будет надежнее
      ensure
        set_state(STATE_STOPPED) rescue nil
        logger.warn "Supervisor остановлен"
      end
    end

    protected

    def initialize(supervisor_info)
      @process_object = supervisor_info
    end

    def run_initializers
      in_initialize = Models::Field.in_initialize.select { |field| process_is_alive?(field.pid) }.size
      available_for_run = [MAX_INITIALIZERS - in_initialize, 0].max
      fields = fields_for_initialize.take(available_for_run)
      #logger.debug "run_initializers, available_for_run = #{available_for_run}, fields.count = #{fields.count}"
      fields.each { |field| run_initializer(field) }
    end

    def fields_for_initialize
      Models::Field
        .active
        .for_initialize_or_in_initialize
        .ordered
        .select do |field|
          field.state.eql?(Fields::STATE_NEED_INITIALIZE) ||
            (field.state.eql?(Fields::STATE_IN_INITIALIZE) && process_is_dead?(field.pid))
        end
    end

    def run_initializer(field)
      @client = BgExecutor::Client.instance
      @job_id = @client.queue_job!('treasury/initialize_field', field_class: field.field_class)
      logger.info "Запущен джоб иницилизации поля #{quote(field.field_class)}, job_id = #{@job_id}"
    rescue => e
      logger.error "Ошибка при запуске джоба иницилизации поля #{quote(field.field_class)}:"
      log_error(e)
    end

    def run_workers
      ::Treasury::Worker.available.each { |worker| run_worker(worker) }
    end

    def run_worker(worker)
      return if process_is_alive?(worker.pid)

      @client = BgExecutor::Client.instance
      @job_id = @client.queue_job!('treasury/worker', worker_id: worker.id)

      logger.info "Запущен джоб воркер #{quote(worker.id)}, job_id = #{@job_id}"
    rescue => e
      logger.error "Ошибка при запуске воркера #{quote(worker.id)}:"
      log_error(e)
    end

    def check_active
      return true if @process_object.active?
      logger.warn "Supervisor не активен"
      false
    end

    include Treasury::Utils
    include Treasury::Session
    include Treasury::Logging
    include Errors

    #self.logger_file_name :supervisor
    def self.logger_default_file_name
      LOGGER_FILE_NAME
    end
  end
end
