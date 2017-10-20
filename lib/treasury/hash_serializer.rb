module Treasury
  module HashSerializer
    def deserialize(hash_string)
      return Hash.new if hash_string.blank?

      hash_data = hash_string
        .split(',')
        .map do |item|
          key, value = item.split(':')
          [key, value.to_i]
        end

      Hash[hash_data]
    end

    def serialize(hash)
      hash.is_a?(Hash) && !hash.empty? ? hash.map { |key, value| "#{key}:#{value}" }.join(',') : nil
    end
  end
end
