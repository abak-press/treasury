# coding: utf-8

module Treasury
  module Fields
    module Accessors
      def value_as_string(params)
        raise_no_implemented(:string, params)
      end

      def value_as_integer(params)
        raise_no_implemented(:integer, params)
      end

      def value_as_boolean(params)
        raise_no_implemented(:boolean, params)
      end

      def value_as_date(params)
        raise_no_implemented(:date, params)
      end

      def value_as_array(params)
        raise_no_implemented(:array, params)
      end

      private

      def raise_no_implemented(accessor_type, params)
        raise Errors::NoAccessor.new(self, accessor_type, params)
      end
    end
  end
end
