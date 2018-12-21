module Treasury
  class Worker
    STATE_RUNNING = 'running'.freeze
    STATE_STOPPED = 'stopped'.freeze

    REFRESH_FIELDS_LIST_PERIOD     = Rails.env.staging? || !Rails.env.production? ? 1.minute : 1.minute
    IDLE_MAX_LAG                   = 2.minutes
    PROCESS_LOOP_NORMAL_SLEEP_TIME = Rails.env.test? ? 0 : 0.seconds
    PROCESS_LOOP_IDLE_SLEEP_TIME   = Rails.env.test? ? 0 : 5.seconds

    LOGGER_FILE_NAME = "#{ROOT_LOGGER_DIR}/workers/%{name}_worker".freeze

    module Errors
      class WorkerError < StandardError; end
      class UnknownWorkerError < StandardError; end
    end

    cattr_accessor :name

    def self.run(worker_id)
      worker = Models::Worker.find(worker_id)
      raise UnknownWorkerError if worker.nil?
      self.name = worker.name
      self.new(worker).process
    end

    def initialize(worker_info)
      @process_object = worker_info
    end

    def current_worker
      @process_object
    end

    def process
      logger.warn "Worker запущен"
      begin
        return unless check_active
        set_state(STATE_RUNNING)
        clear_last_error
        while true
          break unless check_terminate
          processed = process_fields
          break if !processed && Rails.env.test?
          idle(processed)
        end
      rescue Exception => e
        log_error(e)
        raise
      ensure
        set_state(STATE_STOPPED) rescue nil
        logger.warn "Worker остановлен"
      end
    end

    def idle(mode)
      if mode
        sleep(PROCESS_LOOP_NORMAL_SLEEP_TIME)
      else
        sleep(PROCESS_LOOP_IDLE_SLEEP_TIME)
      end
    end

    def process_fields
      refresh_fields_list

      idle = true
      total_lag = 0
      processed_queues = 0

      @processing_fields.each do |field|
        begin
          begin
            next if field.need_initialize?

            field.processors.each do |processor|
              start_time = Time.now
              result_hash = processor.processor_class.constantize.new(processor, logger).process
              events_processed = result_hash[:events_processed]
              unless events_processed.zero?
                work_time = Time.now - start_time

                if work_time != 0
                  logger.info "Обработано #{events_processed} событий, за #{work_time.round(1)}"\
                              " с (#{(events_processed.to_f / work_time).round(1)} eps),"\
                              " записано #{result_hash[:rows_written]} [#{processor.consumer_name}]"
                end
              end

              total_lag += @consumers_info[processor.consumer_name].try(:[], :seconds_lag).to_i
              idle &&= events_processed.zero?
              processed_queues += 1
            end
          rescue Pgq::Errors::QueueOrSubscriberNotFoundError, Processors::Errors::InconsistencyDataError => e
            # обработка исключений, требующих переиницилизации поля
            logger.warn "Поле помечено как не иницилизированное."
            field.need_initialize!
            raise
          end
        rescue StandardError, NotImplementedError => e
          raise if Rails.env.test?
          logger.error "Ошибка при обработке поля #{field.title}:"
          log_error(e)
        end
      end

      unless Rails.env.test? || processed_queues.zero?
        idle &&= total_lag / processed_queues < IDLE_MAX_LAG
      end

      !idle
    end

    def refresh_fields_list
      return if @last_update && (Time.now - @last_update < REFRESH_FIELDS_LIST_PERIOD)

      @processing_fields = processing_fields

      refresh_consumers_info
      @last_update = Time.now
    end

    # Public: Возвращает массив полей для обработки.
    #
    # В окружении, отличном от production, все поля обрабатываются одним воркером.
    #
    # Returns Array of Treasury::Models::Field.
    #
    def processing_fields
      processing_fields =
        Treasury::Models::Field
        .for_processing
        .joins(processors: :queue)
        .eager_load(processors: :queue)

      if Rails.env.production? && !Rails.env.staging?
        processing_fields = processing_fields.where(worker_id: current_worker.id)
      end

      processing_fields.to_a
    end

    def refresh_consumers_info
      work_connections =
        @processing_fields
        .map(&:processors)
        .flatten
        .map(&:queue)
        .map(&:work_connection)
        .uniq

      @consumers_info = HashWithIndifferentAccess.new
      work_connections.each do |connection|
        Pgq::Consumer.get_consumer_info(connection).each do |consumer|
          @consumers_info.merge!(consumer['consumer_name'] => HashWithIndifferentAccess.new(consumer))
        end
      end
    end

    def check_active
      return true if @process_object.active?
      logger.warn "Worker не активен"
      false
    end

    def main_connection
      ActiveRecord::Base.connection
    end

    include Treasury::Utils
    include Treasury::Session
    include Treasury::Logging
    include Errors

    def self.logger_default_file_name
      LOGGER_FILE_NAME % [name: name]
    end

    self.logger_level = Logger::INFO
  end
end
