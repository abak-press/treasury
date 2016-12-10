module Treasury
  module Processors
    module DataAccessors
      extend ActiveSupport::Concern

      included do
        class_attribute :data_fields
        self.data_fields = []
      end

      module ClassMethods
        # Определяет акцессоры для доступа к переданным в процессор данным
        #
        #
        # Например:
        #
        #  class Cosmos::Treasury::Processors::Company::NewOrders
        #    include ::Treasury::Processors::DataAccessors
        #
        #    define_fields :user_id, order_type, fast_parsing: true
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
        def define_fields(*args)
          options = args.extract_options!
          data_field_names = Array.wrap args

          data_method, prev_data_method =
            options.fetch(:fast_parsing, false) ? [:raw_data, :raw_prev_data] : [:data, :prev_data]

          data_field_names.each do |field_name|
            class_eval <<-RUBY
              def #{field_name}
                event.#{data_method}.fetch(:#{field_name})
              end

              def prev_#{field_name}
                event.#{prev_data_method}.fetch(:#{field_name})
              end

              def #{field_name}_changed?
                #{field_name} != prev_#{field_name}
              end
            RUBY
          end

          data_fields.concat data_field_names
        end
      end
    end
  end
end
