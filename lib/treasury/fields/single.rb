module Treasury
  module Fields
    module Single
      extend ActiveSupport::Concern

      module ClassMethods
        protected

        def init_accessor(params)
          @accessing_object = extract_object(params)
          @accessing_field  = nil
        end
      end
    end
  end
end
