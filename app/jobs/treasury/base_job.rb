module Treasury
  class BaseJob < Treasury::BgExecutor::Job::Indicated
    acts_as_no_cancel
    acts_as_critical notify_email: Treasury.configuration.job_error_notifications
  end
end
