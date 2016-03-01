# coding: utf-8

module Treasury
  module Processors
    class Base < ::CoreDenormalization::Processors::Base
      def form_value(value)
        value
      end

      def result_row(value)
        {@object => form_value(value)}
      end
    end
  end
end
