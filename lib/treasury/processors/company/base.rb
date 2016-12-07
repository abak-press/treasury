# coding: utf-8

module Treasury
  module Processors
    module Company
      class Base < ::Treasury::Processors::Base
        alias :company_id= :object=
        alias :company_id :object

        protected

        def init_event_params
          self.company_id = extract_company.to_i.nonzero?
          raise ArgumentError, "Company ID expected to be Integer, #{@event.inspect}" unless company_id
        end

        def extract_company
          @event.raw_data.key?(:company_id) ? @event.raw_data[:company_id] : @event.raw_data[:id]
        end
      end
    end
  end
end
