module Treasury
  module Processors
    module HashOperations
      include HashSerializer

      def increment_raw_value(raw_hash, key, step = 1)
        numeric_key = key.to_i
        process_value(raw_hash) do |data|
          data[numeric_key] = data[numeric_key].to_i + step.to_i
        end
      end

      def decrement_raw_value(raw_hash, key, step = 1)
        numeric_key = key.to_i
        process_value(raw_hash) do |data|
          if data.key?(numeric_key)
            new_value = data[numeric_key] - step.to_i
            if new_value > 0
              data[numeric_key] = new_value
            else
              data.delete numeric_key
            end
          end
        end
      end

      private

      def process_value(raw_hash)
        return raw_hash unless block_given?

        data = deserialize(raw_hash)
        yield data
        serialize data
      end
    end
  end
end
