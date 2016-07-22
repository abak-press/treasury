# coding: utf-8
module Treasury
  module Fields
    module Errors
      class FieldError < StandardError
      end

      class UnknownFieldClassError < StandardError
      end

      class UninitializedFieldError < StandardError
      end

      class NoAccessor < FieldError
        def initialize(klass, accessor_type, params)
          super "Класс #{klass} не реализует доступ к полю как к #{accessor_type}, #{params.inspect}"
        end
      end
    end
  end
end
