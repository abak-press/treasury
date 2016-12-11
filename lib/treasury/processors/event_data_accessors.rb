module Treasury
  module Processors
    module EventDataAccessors
      extend ActiveSupport::Concern

      module ClassMethods
        # Определяет акцессоры для доступа к переданным в процессор данным
        #
        #
        # Например:
        #
        #  class Cosmos::Treasury::Processors::Company::NewOrders
        #    include ::Treasury::Processors::EventDataAccessors
        #
        #    event_data_fields :user_id, order_type, fast_parsing: true
        #  end
        #
        # Аргументы:
        #   names : String, Symbol, Array - имена полей для доступа к данным
        #   options : Hash
        #     fast_parsing : Boolean - Использовать быстрый алгоритм для парсинга параметров события
        #                              Работает не всегда, поэтому значение по умолчанию false
        # Результат:
        #   доступные методы:
        #     user_id, prev_user_id, user_id_changed?
        #     order_type, prev_order_type, order_type_changed?
        def event_data_fields(*args)
          options = args.extract_options!
          data_field_names = Array.wrap args

          data_method, prev_data_method =
            options.fetch(:fast_parsing, false) ? [:raw_data, :raw_prev_data] : [:data, :prev_data]

          data_field_names.each do |field_name|
            define_method(field_name) do
              event.send(data_method).fetch(field_name)
            end
            define_method("prev_#{field_name}") do
              event.send(prev_data_method).fetch(field_name)
            end

            define_method("#{field_name}_changed?") do
              self.send(field_name) != self.send("prev_#{field_name}")
            end
          end
        end
      end
    end
  end
end
