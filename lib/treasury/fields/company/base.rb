# coding: utf-8

module Treasury
  module Fields
    module Company
      #
      # Базовый класс - Поле системы денормализации, для полей на основе компании.
      #
      class Base < Treasury::Fields::Base
        BATCH_SIZE = 10_000

        protected

        # Protected: Инициализирует параметры поля.
        #
        # Returns nothing.

        def init_params
          super
          self.batch_size = BATCH_SIZE
        end

        # Protected: Возвращает идентификатор компании, переданой как объект в параметрах.
        #
        # params - Hash параметров:
        #          :object - String/Numeric/::Company или Hash, содержащий элемент
        #                    :company или :company_id, указанных типов.
        #
        # Returns Numeric.

        def self.extract_object(params)
          company = params[:object]
          company = company[:company] || company[:company_id] if company.is_a?(Hash)

          case company
          when ::Numeric
            company
          when ::String
            company.to_i
          else
            if company && company.respond_to?(:id)
              company.id
            else
              raise ArgumentError, "Company instance or Numeric/String company id expected!', #{params.inspect}"
            end
          end
        end

        class << self
          alias :extract_company :extract_object
        end

        class << self
          alias :accessing_company :accessing_object
        end
      end
    end
  end
end
