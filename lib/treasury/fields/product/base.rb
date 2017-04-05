module Treasury
  module Fields
    module Product
      #
      # Базовый класс - Поле системы денормализации, для полей на основе товара.
      #
      class Base < Treasury::Fields::Base
        extend Apress::Sources::ExtractObject

        extract_attribute_name :product

        BATCH_SIZE = 50_000

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
