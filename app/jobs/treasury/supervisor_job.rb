module Treasury
  class SupervisorJob < BaseJob
    acts_as_singleton

    def execute
      Treasury::Supervisor.run
    end
  end
end
