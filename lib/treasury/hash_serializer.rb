module Treasury
  module HashSerializer
    def deserialize(hash_string)
      hash_string.blank? ? Hash.new : Hash[hash_string.split(',').map { |item| item.split(':').map(&:to_i) }]
    end

    def serialize(hash)
      hash.is_a?(Hash) && !hash.empty? ? hash.map { |key, value| "#{key}:#{value}" }.join(',') : nil
    end
  end
end
