module Treasury
  module Fields
    # Модуль добавляет классу метод extract_object, подходит для источников и полей денормализации.
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
      def extract_object(params)
        object = params.fetch(:object)
        object = object[attribute_name.to_sym] || object["#{attribute_name}_id".to_sym] if object.is_a?(Hash)

        case object
        when ::Numeric
          object
        when ::String
          object.to_i
        else
          if object && object.respond_to?(:id)
            object.id
          else
            raise ArgumentError,
                  "#{attribute_name.capitalize} instance or Numeric/String #{attribute_name}_id expected!, "\
                  "#{params.inspect}"
          end
        end
      end

      def extract_attribute_name(name)
        class_attribute :attribute_name, instance_writer: false

        self.attribute_name = name
      end
    end
  end
end
