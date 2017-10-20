module Treasury
  module Processors
    module HashOperations
      include HashSerializer

      def increment_raw_value(raw_hash, key, step = 1)
        key_string = key.to_s
        process_value(raw_hash) do |data|
          data[key_string] = data[key_string].to_i + step.to_i
        end
      end

      def decrement_raw_value(raw_hash, key, step = 1)
        key_string = key.to_s
        process_value(raw_hash) do |data|
          if data.key?(key_string)
            new_value = data[key_string] - step.to_i
            if new_value > 0
              data[key_string] = new_value
            else
              data.delete key_string
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
