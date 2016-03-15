# coding: utf-8

module Treasury
  module Processors
    class Base < ::CoreDenormalization::Processors::Base
      attr_accessor :object
      
      def current_value(field_name = nil)
        object_value(@object, field_name)
      end

      def object_value(l_object, field_name = nil)
        value = if @data.key?(l_object)
                  @data[l_object][field_name || field.first_field]
                else
                  field.raw_value(l_object, field_name)
                end
        log_event(:message => "get object #{l_object} value", :payload => value)
        value
      end

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
