# coding: utf-8

module Treasury
  module BgExecutor
    class Daemon
      BGE_PROCESS_NAME = 'bg_executor_job.rb'.freeze
      private_constant :BGE_PROCESS_NAME

      def initialize
        ActiveRecord::Base.clear_all_connections!

        reconnect!

        enable_gc_optimizations
      end

      def execute_job
        job = client.pop
        return unless job

        wait_till_fork_allowed! do
          log ">>> Executing job :id => #{job[:id]}, :name => #{job[:job_name]}, :args => #{job[:args].inspect}"
          Daemons.run_proc(BGE_PROCESS_NAME, self.daemon_options) do
            begin
              self.reconnect!
              BgExecutor::Executor.new.execute_job(job)
            rescue Exception => e
              begin
                error_log "*** Failed job #{job.inspect}", e
                client.fail_job!(job[:id].to_i, e) if job
              rescue Exception => e2
                client.fail_job!(job[:id].to_i, e) if job
                error_log "*** Failed to mark job as fail", e2
              end

              process_critical_job(job, e)
            ensure
              shoutdown_job!
            end
          end
        end

      rescue Timeout::Error => e
        client.fail_job! job[:id].to_i, BgExecutor::QueueError.new('BgExecutor queue is full. Timeout error.')
        log "Timeout::Error cannot push job(#{job[:id]}) into queue"

        process_critical_job(job, e)
      rescue => e
        begin
          error_log "*** Failed job #{job.inspect}", e
          client.fail_job!(job[:id].to_i, e) if job
        rescue Exception => e2
          client.fail_job!(job[:id].to_i, e) if job
          error_log "*** Failed to mark job as fail", e2
        end

        process_critical_job(job, e)
      end

      protected

      # если это важный job, и он упал, то поставим его опять в очередь
      def process_critical_job(job, e)
        return false unless job.present?

        if job[:args] && job[:args][:_critical]
          job[:args][:_tries] ||= 0

          if job[:args][:_tries] >= Treasury.configuration.bge_max_tries_on_fail
            log "*** Job #{job.inspect} max tries exceeded"

            recipient = job[:args][:notify_email].presence || Conf.general['support_email']
            subject = "BgExecutor: critical job #{job[:job_name]} failed"
            message = "Job #{job.inspect} max tries exceeded"
            Treasury::BgExecutorMailer.notify(recipient, subject, message, e).deliver
          else
            job[:args][:_tries] += 1
            log "> Queue job :name => #{job[:job_name]}, :args => #{job[:args].inspect}"
            client.queue_job! job[:job_name], job[:args]
          end
        end
      rescue Exception => e2
        error_log "*** Failed to restart job", e2
      end

      def reconnect!
        reopen_logs

        logger = Logger.new(rails_logger_filename)
        [Rails, ActiveRecord::Base, ActionController::Base, ActionMailer::Base].each do |logged_class|
          logged_class.logger = logger
        end

        ActiveRecord::Base.connection_handler.connection_pools.each_value do |pool|
          pool.connections.each(&:reconnect!)
        end

        ActiveRecord::Base.verify_active_connections!
      rescue Exception => e
        log "Could not reconnect!"
        log e.message
        log e.backtrace.join("\n")
      end

      def shoutdown_job!
        $running = false
      ensure
        exit()
      end

      def get_concurrency
        Treasury.configuration.bge_concurrency
      end

      def get_queue_timeout
        Treasury.configuration.bge_queue_timeout
      end

      def daemon_options(command = :start)
        {:multiple => true,
         :ontop => false,
         :backtrace => true,
         :dir_mode => :normal,
         :dir => pid_files_dir,
         :log_dir => pid_files_dir,
         :log_output => true,
         :monitor => false,
         :keep_pid_files => true,
         :ARGV => [command.to_s]
        }
      end

      def client
        @client ||= BgExecutor::Client.instance
      end

      def wait_till_fork_allowed!
        if allowed_to_fork?
          yield
          return
        else
          log "Queue is full. Waiting..."
          clean_pids!
        end

        Timeout.timeout(get_queue_timeout) do
          loop do
            if allowed_to_fork?
              yield
              break
            end
            sleep 5
          end
        end
      end

      def allowed_to_fork?
        executors_count < get_concurrency
      end

      def executors_count
        Daemons::PidFile.find_files(pid_files_dir, BGE_PROCESS_NAME, false).size
      rescue Exception => e
        log "Error in executors_count"
        log e.message
        0
      end

      def pid_files_dir
        @pid_files_dir ||= "#{Rails.root}/log"
      end

      def enable_gc_optimizations
        GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)
      end

      # Log message to stdout
      def log(message)
        puts "%s: %s" % [Time.now.to_s, message]
      end

      def error_log(message, exception)
        log "#{message} \n\nError: #{exception.message}\n\nBacktrace: #{exception.backtrace.join("\n")}"
      end

      def clean_pids!
        Daemons::PidFile.find_files("#{Rails.root}/log", BGE_PROCESS_NAME, true)
      end

      private

      # Internal: Рельсовые логи перенаправим в отдельный лог
      #
      # Returns String
      def rails_logger_filename
        @rails_logger_filename ||= Rails.env.development? ? Rails.root.join('log', "bg_executor_#{Rails.env}.log").to_s : '/dev/null'
      end

      # Переоткрытие всех логов
      #
      # @see Unicorn::Utils
      def reopen_logs
        to_reopen = []
        nr = 0
        ObjectSpace.each_object(File) { |fp| is_log?(fp) and to_reopen << fp }

        to_reopen.each do |fp|
          orig_st = begin
            fp.stat
          rescue IOError, Errno::EBADF # race
            next
          end

          begin
            b = File.stat(fp.path)
            next if orig_st.ino == b.ino && orig_st.dev == b.dev
          rescue Errno::ENOENT
          end

          begin
            # stdin, stdout, stderr are special.  The following dance should
            # guarantee there is no window where `fp' is unwritable in MRI
            # (or any correct Ruby implementation).
            #
            # Fwiw, GVL has zero bearing here.  This is tricky because of
            # the unavoidable existence of stdio FILE * pointers for
            # std{in,out,err} in all programs which may use the standard C library
            if fp.fileno <= 2
              # We do not want to hit fclose(3)->dup(2) window for std{in,out,err}
              # MRI will use freopen(3) here internally on std{in,out,err}
              fp.reopen(fp.path, "a")
            else
              # We should not need this workaround, Ruby can be fixed:
              #    http://bugs.ruby-lang.org/issues/9036
              # MRI will not call call fclose(3) or freopen(3) here
              # since there's no associated std{in,out,err} FILE * pointer
              # This should atomically use dup3(2) (or dup2(2)) syscall
              File.open(fp.path, "a") { |tmpfp| fp.reopen(tmpfp) }
            end

            fp.sync = true
            fp.flush # IO#sync=true may not implicitly flush
            new_st = fp.stat

            # this should only happen in the master:
            if orig_st.uid != new_st.uid || orig_st.gid != new_st.gid
              fp.chown(orig_st.uid, orig_st.gid)
            end

            nr += 1
          rescue IOError, Errno::EBADF
            # not much we can do...
          end
        end
        nr
      end

      # @see Unicorn::Utils
      def is_log?(fp)
        append_flags = File::WRONLY | File::APPEND

        !fp.closed? &&
        fp.stat.file? &&
        fp.sync &&
        (fp.fcntl(Fcntl::F_GETFL) & append_flags) == append_flags
      rescue IOError, Errno::EBADF
        false
      end
    end
  end
end
