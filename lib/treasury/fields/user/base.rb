module Treasury
  module Fields
    module User
      #
      # Базовый класс - Поле системы денормализации, для полей на основе пользователя.
      #
      class Base < Treasury::Fields::Base
        extend Apress::Sources::ExtractObject

        extract_attribute_name :user

        BATCH_SIZE = 25_000

        protected

        # Protected: Инициализирует параметры поля.
        #
        # Returns nothing.

        def init_params
          super
          self.batch_size = BATCH_SIZE
        end
      end
    end
  end
end
