module Treasury
  module BgExecutor
    class Executor
      def client
        @client ||= BgExecutor::Client.instance
      end

      def execute_job(job_hash)
        id, name, args = job_hash[:id].to_i, job_hash[:job_name], job_hash[:args]
        job = Treasury::BgExecutor::Job.create(id, name, args)

        $0 = "Job ##{job_hash[:id]}: #{job.title || name}"

        log ">>> Executing job :id => #{id}, :name => #{name}, :args => #{args.inspect}"

        client.start_job! id

        job.execute

        client.finish_job! id

        log "*** Finished job ##{id}"
        $0 = "Job ##{job_hash[:id]}: #{job.title || name}*"
      end

      # Log message to stdout
      def log(message)
        puts "%s: %s" % [Time.now.to_s, message]
      end
    end # end class
  end # end module
end
