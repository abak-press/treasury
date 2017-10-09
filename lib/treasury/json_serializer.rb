module Treasury
  module JsonSerializer
    def deserialize(hash_string)
      hash_string.blank? ? {} : Oj.load(hash_string)
    end

    def serialize(hash)
      hash.is_a?(Hash) && !hash.empty? ? Oj.dump(hash) : nil
    end
  end
end
