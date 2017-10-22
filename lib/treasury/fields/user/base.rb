module Treasury
  module Fields
    module User
      #
      # Базовый класс - Поле системы денормализации, для полей на основе пользователя.
      #
      class Base < Treasury::Fields::Base
        extend Apress::Sources::ExtractObject

        extract_attribute_name :user

        self.default_batch_size = 25_000
      end
    end
  end
end
