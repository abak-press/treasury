module Treasury
  module Processors
    module Company
      class Base < ::Treasury::Processors::Base
        alias :company_id= :object=
        alias :company_id :object

        alias :prev_company_id= :prev_object=
        alias :prev_company_id  :prev_object

        protected

        def init_event_params
          self.company_id = extract_company.to_i.nonzero?
          self.prev_company_id = extract_prev_company.to_i.nonzero?

          raise ArgumentError, "Company ID expected to be Integer, #{@event.inspect}" unless company_id
        end

        def extract_company
          @event.raw_data.key?(:company_id) ? @event.raw_data[:company_id] : @event.raw_data[:id]
        end

        def extract_prev_company
          @event.raw_prev_data.key?(:company_id) ? @event.raw_prev_data[:company_id] : @event.raw_prev_data[:id]
        end
      end
    end
  end
end
