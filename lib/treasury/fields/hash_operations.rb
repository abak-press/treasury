module Treasury
  module Fields
    module HashOperations
      extend ActiveSupport::Concern

      module ClassMethods
        def value_as_hash(params)
          init_accessor(params)
          deserialize(value.to_s)
        end
      end
    end
  end
end
