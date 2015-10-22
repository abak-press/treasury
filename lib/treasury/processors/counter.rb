module Treasury
  module Processors
    module Counter
      include Single

      protected

      def process_insert
        increment_current_value if satisfied?
      end

      def process_update
        if satisfied?
          increment_current_value unless was_counted?
        else
          decrement_current_value if was_counted?
        end
      end

      def process_delete
        decrement_current_value if was_counted?
      end

      def satisfied?
        condition? @event.raw_data
      end

      def was_counted?
        condition? @event.raw_prev_data
      end

      def condition?(data)
        raise NotImplemenedError
      end
    end
  end
end