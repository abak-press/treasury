# coding: utf-8

module Treasury
  module Processors
    module Single

      protected

      def storage_field
        @storage_field ||= field.first_field.to_sym
      end

      def form_value(value)
        {storage_field => value}
      end

      def increment_current_value(field_name = nil, by = 1)
        result_row(incremented_current_value(field_name, by))
      end

      def decrement_current_value(field_name = nil, by = 1)
        result_row(decremented_current_value(field_name, by))
      end
    end
  end
end
