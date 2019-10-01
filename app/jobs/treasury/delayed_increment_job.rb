module Treasury
  class DelayedIncrementJob
    include Resque::Integration

    queue :base
    retrys

    # Public: Отложенный инкремент поля
    #
    # params - Hash:
    #          'object'      - Integer идентификатор
    #          'field_name'  - String название поля
    #          'field_class' - String класс поля
    #          'by'          - Integer приращение
    #
    # Returns nothing
    def self.perform(params)
      object     = params.fetch('object')
      field_name = params.fetch('field_name')
      increment  = params.fetch('by')

      field = Treasury::Fields::Base.create_by_class(params.fetch('field_class'))
      new_value = field.raw_value(object, field_name).to_i + increment

      field.write_data({object => {field_name => new_value}}, true)
    end
  end
end
