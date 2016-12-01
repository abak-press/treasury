module Treasury
  class WorkerJob < BaseJob
    acts_as_singleton [:worker_id]

    def execute
      Worker.run(params[:worker_id])
    end

    def title
      "#{self.class.name.underscore.gsub('_job', '')}:#{worker.name}"
    end

    protected

    def worker
      @worker ||= Treasury::Models::Worker.find(params[:worker_id])
    end
  end
end
