module Treasury
  module Processors
    module Delayed
      # Отложенное приращение текущего значения поля
      #
      # field_name - String
      # seconds    - Integer
      #
      # Returns nothing
      def delayed_increment_current_value(field_name, seconds)
        delayed_change_current_value(field_name, seconds, 1)
      end

      # Отложенное уменьшение текущего значения поля
      #
      # field_name - String
      # seconds    - Integer
      #
      # Returns nothing
      def delayed_decrement_current_value(field_name, seconds)
        delayed_change_current_value(field_name, seconds, -1)
      end

      # Отмена отложенного приращения значения
      # Note: возвращает false если отложенной задачи не найдено
      #
      # field_name - String
      #
      # Returns boolean
      def cancel_delayed_increment(field_name)
        cancel_delayed_change(field_name, 1)
      end

      # Отмена отложенного уменьшения значения
      # Note: возвращает false если отложенной задачи не найдено
      #
      # field_name - String
      #
      # Returns boolean
      def cancel_delayed_decrement(field_name)
        cancel_delayed_change(field_name, -1)
      end

      private

      # Internal: Отложенное изменение текущего значения поля на указанную величину
      #
      # field_name - String
      # seconds    - Integer
      # by         - Integer величина, на которую нужно изменить
      #
      # Returns nothing
      def delayed_change_current_value(field_name, seconds, by)
        job_params = delayed_increment_job_params(field_name, by)
        Resque.enqueue_in(seconds, Treasury::DelayedIncrementJob, job_params)

        no_action
      end

      # Internal: Отмена отложенного изменения значения
      # Note: возвращает false если отложенной задачи не найдено
      #
      # field_name - String
      #
      # Returns boolean
      def cancel_delayed_change(field_name, by)
        job_params = delayed_increment_job_params(field_name, by)
        removed = Resque.remove_delayed(Treasury::DelayedIncrementJob, job_params)

        !removed.zero?
      end

      def delayed_increment_job_params(field_name, by)
        delayed_job_params.merge! field_name: field_name, by: by
      end

      def delayed_job_params
        {
          id: event.data.fetch(:id),
          object: @object,
          field_class: field_class
        }
      end
    end
  end
end
