module Treasury
  module Fields
    module Delayed
      protected

      # Internal: Отмена отложенных задач по приращению
      #
      # Returns Integer количество отмененных задач
      def cancel_delayed_increments
        Resque.remove_delayed_selection(Treasury::DelayedIncrementJob) do |args|
          args[0]['field_class'] == field_model.field_class
        end
      end
    end
  end
end
