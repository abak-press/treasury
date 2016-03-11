# coding: utf-8

module Treasury
  module Processors
    class Base < ::CoreDenormalization::Processors::Base
      attr_accessor :object

      def form_value(value)
        value
      end

      def result_row(value)
        {@object => form_value(value)}
      end

      def no_action
        nil
      end
    end
  end
end
