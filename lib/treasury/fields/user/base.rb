# coding: utf-8

module Treasury
  module Fields
    module User
      #
      # Базовый класс - Поле системы денормализации, для полей на основе пользователя.
      #
      class Base < Treasury::Fields::Base
        BATCH_SIZE = 25_000

        protected

        # Protected: Инициализирует параметры поля.
        #
        # Returns nothing.

        def init_params
          super
          self.batch_size = BATCH_SIZE
        end

        # Protected: Возвращает идентификатор пользователя, переданного как объект в параметрах.
        #
        # params - Hash параметров:
        #          :object - String/Numeric/::User или Hash, содержащий элемент
        #                    :user или :user_id, указанных типов.
        #
        # Returns Numeric.

        def self.extract_object(params)
          user = params[:object]
          user = user[:user] || user[:user_id] if user.is_a?(Hash)

          case user
          when ::Numeric
            user
          when ::String
            user.to_i
          else
            if user && user.respond_to?(:id)
              user.id
            else
              raise ArgumentError, "User instance or Numeric/String user id expected!', #{params.inspect}"
            end
          end
        end

        class << self
          alias :extract_user :extract_object
        end

        class << self
          alias :accessing_user :accessing_object
        end
      end
    end
  end
end
