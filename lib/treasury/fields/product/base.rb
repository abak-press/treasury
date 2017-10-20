module Treasury
  module Fields
    module Product
      #
      # Базовый класс - Поле системы денормализации, для полей на основе товара.
      #
      class Base < Treasury::Fields::Base
        extend Apress::Sources::ExtractObject

        extract_attribute_name :product

        self.default_batch_size = 50_000
      end
    end
  end
end
