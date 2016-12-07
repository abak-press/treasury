# coding: utf-8

module Treasury
  module Fields
    module Product
      #
      # Базовый класс - Поле системы денормализации, для полей на основе товара.
      #
      class Base < Treasury::Fields::Base
        BATCH_SIZE = 50_000

        protected

        # Protected: Инициализирует параметры поля.
        #
        # Returns nothing.

        def init_params
          super
          self.batch_size = BATCH_SIZE
        end

        # Protected: Возвращает идентификатор товара, переданного как объект в параметрах.
        #
        # params - Hash параметров:
        #          :object - String/Numeric/::Product или Hash, содержащий элемент
        #                    :product или :product_id, указанных типов.
        #
        # Returns Numeric.

        def self.extract_object(params)
          product = params.fetch(:object)
          product = product.fetch(:product) || product.fetch(:product_id) if product.is_a?(Hash)

          case product
          when ::Numeric
            product
          when ::String
            product.to_i
          else
            if product && product.respond_to?(:id)
              product.id
            else
              raise ArgumentError, "Product instance or Numeric/String product id expected!', #{params.inspect}"
            end
          end
        end

        class << self
          alias :extract_product :extract_object
          alias :accessing_product :accessing_object
        end
      end
    end
  end
end
