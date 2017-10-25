module Treasury
  module Fields
    module Company
      #
      # Базовый класс - Поле системы денормализации, для полей на основе компании.
      #
      class Base < Treasury::Fields::Base
        extend Apress::Sources::ExtractObject

        extract_attribute_name :company

        self.default_batch_size = 10_000
      end
    end
  end
end
