module Treasury
  module Storage
    module Redis
      # хранилище на основе Redis
      # данные хранятся в виде хэша строк
      class Multi < Base
        DEFAULT_ID = :redis_multi

        def read(object, field)
          hget(object, field)
        end

        protected

        def write(object, data)
          data.each { |field, value| hset(object, field, value) }
          expire(object, params[:expire]) if params[:expire]
        end

        def default_id
          DEFAULT_ID
        end
      end
    end
  end
end
