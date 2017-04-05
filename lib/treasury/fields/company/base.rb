module Treasury
  module Fields
    module Company
      #
      # Базовый класс - Поле системы денормализации, для полей на основе компании.
      #
      class Base < Treasury::Fields::Base
        extend Apress::Sources::ExtractObject

        extract_attribute_name :company

        BATCH_SIZE = 10_000

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
