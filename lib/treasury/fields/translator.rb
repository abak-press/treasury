# coding: utf-8

module Treasury
  module Fields
    module Translator
      extend ActiveSupport::Concern

      module ClassMethods
        def value_as_string(params)
          init_accessor(params)
          value.to_s
        end

        def value_as_integer(params)
          value_as_string(params).to_i
        end

        def value_as_boolean(params)
          value_as_string(params).mb_chars.downcase.to_b
        end

        def value_as_date(params)
          value_as_string(params).to_date
        end
      end
    end
  end
end
