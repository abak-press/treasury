module Treasury
  module Processors
    module Counters
      extend ActiveSupport::Concern

      included do
        class_attribute :counters_list
        self.counters_list = []
      end

      module ClassMethods
        # Определяет значения поля, которые должны вести себя как счетчик.
        #
        # Для каждого счетчика требуется задать условие начисления.
        # Это делается путем определения одноименного метода-предиката
        #
        # Например:
        #
        #  class Cosmos::Treasury::Processors::Company::NewOrders
        #    include ::Treasury::Processors::Counters
        #
        #    counter :new_orders_count, fast_parsing: true
        #
        #    def new_orders_count?
        #      @raw_data.fetch(:status) == 'pending'
        #    end
        #  end
        #
        # Аргументы:
        #   names : String, Symbol, Array - имена счетчиков
        #   options : Hash
        #     fast_parsing : Boolean - Использовать быстрый алгоритм для парсинга параметров события
        #                              Работает не всегда, поэтому значение по умолчанию false
        # Возвращает:
        #   Список счетчиков после добавления новых
        def counters(*args)
          options = args.extract_options!
          counters = Array.wrap args

          data_method, prev_data_method = if options.fetch(:fast_parsing, false)
                                            [:raw_data, :raw_prev_data]
                                          else
                                            [:data, :prev_data]
                                          end
          counters.each do |name|
            define_method("#{name}?") do |data|
              raise NotImplementedError
            end

            class_eval <<-RUBY
              def #{name}_satisfied?
                #{name}? @event.#{data_method}
              end

              def #{name}_was_counted?
                #{name}? @event.#{prev_data_method}
              end
            RUBY
          end

          counters_list.concat counters
        end

        alias_method :counter, :counters
      end

      def process_insert
        fields = counters_list.each_with_object({}) do |counter, hash|
          hash[counter] = incremented_current_value(counter) if send "#{counter}_satisfied?"
        end
        result_row(fields) if fields.present?
      end

      def process_update
        fields = counters_list.each_with_object({}) do |counter, hash|
          if send "#{counter}_satisfied?"
            hash[counter] = incremented_current_value(counter) unless send "#{counter}_was_counted?"
          else
            hash[counter] = decremented_current_value(counter) if send "#{counter}_was_counted?"
          end
        end
        result_row(fields) if fields.present?
      end

      def process_delete
        fields = counters_list.each_with_object({}) do |counter, hash|
          hash[counter] = decremented_current_value(counter) if send "#{counter}_was_counted?"
        end
        result_row(fields) if fields.present?
      end
    end
  end
end
