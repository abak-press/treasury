module Treasury
  class Controller
    SUPERVISOR_TERMINATE_TIMEOUT = 10 # seconds
    SUPERVISOR_JOB_NAME = 'treasury/supervisor'.freeze
    SUPERVISOR_CMDLINE_PATTERN = ': treasury/[s]upervisor'.freeze
    WORKERS_TERMINATE_TIMEOUT = 60 # seconds
    WORKER_CMDLINE_PATTERN = ': treasury/[w]orker'.freeze
    WORKER_JOB_NAME = 'treasury/worker'.freeze
    MUTEX_NAME = :treasury_controller

    class << self
      # Start Supervisor
      def start
        ::Redis::Mutex.with_lock(MUTEX_NAME, expire: ::Treasury::DEFAULT_LOCK_EXPIRATION) do
          puts 'Starting denormalization service...'

          unless supervisor
            puts 'No Supervisor configured.'
            return
          end

          if bg_executor_client.singleton_job_running?(SUPERVISOR_JOB_NAME, [])
            puts 'Supervisor is already running'
          else
            puts 'run...'
            job_id, job_key = bg_executor_client.queue_job!(SUPERVISOR_JOB_NAME)
            puts 'Supervisor successfully running, job_id = %s, job_key = %s' % [job_id, job_key]
          end
        end
      end

      # Stop Supervisor and all Workers
      def stop
        ::Redis::Mutex.with_lock(MUTEX_NAME, expire: ::Treasury::DEFAULT_LOCK_EXPIRATION) do
          puts 'Stopping denormalization service...'

          unless supervisor
            puts 'No Supervisor configured.'
            return
          end

          stop_supervisor

          terminate_all_workers
          reset_all_workers_jobs

          true
        end
      end

      # Restart Supervisor and all Workers
      def restart
        puts 'Restarting denormalization service...'

        unless supervisor
          puts 'No Supervisor configured.'
          return
        end

        stop
        start
      end

      def stop_supervisor
        ::Redis::Mutex.with_lock(MUTEX_NAME, expire: ::Treasury::DEFAULT_LOCK_EXPIRATION) do
          unless supervisor
            puts 'No Supervisor configured.'
            return
          end

          if supervisor_pid.present?
            puts 'Supervisor is running. Send command to stop...'
            supervisor.terminate

            begin
              Timeout.timeout(SUPERVISOR_TERMINATE_TIMEOUT) do
                sleep(5.seconds) while supervisor_pid.present?
                puts 'Supervisor stopped.'
              end
            rescue Timeout::Error
              puts 'Timeout expired. Terminating...'
              terminate_supervisor
            end
          else
            puts 'Supervisor is not running.'
          end

          puts 'Reset supervisor job state...'
          supervisor.reset_need_terminate
          reset_supervisor_job
        end
      end

      # Дает команду на завершение работы всем рабочим процессам
      def terminate_all_workers
        puts 'Terminate all workers...'

        begin
          Timeout.timeout(WORKERS_TERMINATE_TIMEOUT) do
            while workers_pids.present?
              Treasury::Models::Worker.all.each(&:terminate)
              sleep(5.seconds)
            end
            puts 'Workers stopped.'
          end
        rescue Timeout::Error
          puts "Timeout expired"

          pids = workers_pids
          return unless pids

          puts "Terminating pids #{pids.join(' ')}..."
          `kill -9 #{pids.join(' ')}`
        end
      end

      private

      # Internal: denormalization worker pids by cmd line pattern
      #
      # Returns Array | nil
      def workers_pids
        pgrep_result = `pgrep -f '#{WORKER_CMDLINE_PATTERN}'`.split("\n")
        return unless $CHILD_STATUS.success?

        pgrep_result
      end

      # Internal: denormalization supervisor pid by cmd line pattern
      #
      # Returns Array | nil
      def supervisor_pid
        pgrep_result = `pgrep -f '#{SUPERVISOR_CMDLINE_PATTERN}'`.split("\n")
        return unless $CHILD_STATUS.success?

        pgrep_result
      end

      def reset_supervisor_job
        bg_executor_client.send(:remove_from_singletons,
                                bg_executor_client.job_class(SUPERVISOR_JOB_NAME).singleton_hexdigest({}))
      end

      def reset_all_workers_jobs
        puts 'Reset workers jobs state...'
        Treasury::Models::Worker.all.each do |worker|
          bg_executor_client.send(
            :remove_from_singletons,
            bg_executor_client.job_class(WORKER_JOB_NAME).singleton_hexdigest(worker_id: worker.id)
          )
        end
      end

      def bg_executor_client
        Treasury::BgExecutor::Client.instance
      end

      def terminate_supervisor
        pid = supervisor_pid
        return unless pid.present?

        `kill -9 #{pid.join(' ')}`

        Timeout.timeout(SUPERVISOR_TERMINATE_TIMEOUT) do
          sleep(5.seconds) while supervisor_pid.present?
          puts 'Supervisor terminated.'
        end
      end

      def supervisor
        Treasury::Models::SupervisorStatus.first
      end
    end
  end
end
