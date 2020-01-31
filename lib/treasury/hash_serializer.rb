module Treasury
  module HashSerializer
    INT_PATTERN = /\A\d+\Z/.freeze
    DATE_PATTERN = /\A[1,2][0-9]{3}-(?:0[1-9]|1[0-2])-(?:[0-2][1-9]|3[0-1])\Z/.freeze

    def deserialize(hash_string)
      return Hash.new if hash_string.blank?

      hash_data = hash_string
        .split(',')
        .map do |item|
          key, value = item.split(':')

          if value =~ INT_PATTERN
            [key, value.to_i]
          elsif value =~ DATE_PATTERN
            [key, value.to_date]
          else
            [key, value]
          end
        end

      Hash[hash_data]
    end

    def serialize(hash)
      hash.is_a?(Hash) && !hash.empty? ? hash.map { |key, value| "#{key}:#{value}" }.join(',') : nil
    end
  end
end
