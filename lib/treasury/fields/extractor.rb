module Treasury
  module Fields
    # Public: Модуль добавляет классу метод extract_object, подходит для источников и полей денормализации.
    #
    # Deprecated: For extract object use Apress::Sources::ExtractObject module
    #
    # Example:
    #
    #   class Field
    #     extend ::Treasury::Fields::Extractor
    #     extract_attribute_name :user
    #   end
    #
    #   Field.extract_object(object: {user_id: 1})
    #     => 1
    module Extractor
      def self.extended(base)
        warn "[DEPRECATION] Please use `extend Apress::Sources::ExtractObject` instead Treasury::Fields::Extractor"
        base.extend(Apress::Sources::ExtractObject)
      end
    end
  end
end
