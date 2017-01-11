# coding: utf-8

module Treasury
  module Processors
    # процессор - транслятор данных
    # транслирует данные поступающие в очередь - в хранилище
    # параметры:
    #   :fields_map => [{:source => source_field, :target => target_field}]
    #   - карта полей, массив хэшей, указывающий какое поле источника куда положить в хранилище
    #   По умолчанию: все поля.
    # при изменении данных, хотя бы в одном поле, возвращает полный хэш значений
    # Позволяет, в потомке с помощью перекрытия метода need_translate?,
    # задать какие данные нужны, а какие нет.
    module Translator
      protected

      # Protected: Нужно ли транслировать в хранилище текущую строку.
      #
      # Позволяет задать произвольное условие, которое определяет,
      # какие строки нужно хранить, а какие нет.
      # Строки, для которых данный метод вернул false, не будут записаны
      # в хранилище при insert и будут удалены при update событиях.
      #
      # data - Hash - данные события
      #
      # Returns Boolean.
      def need_translate?(data)
        true
      end

      def process_insert
        return no_action unless need_translate?(@event.data)

        result_row(
          fields_map.inject(result_hash) do |result, field|
            result.merge!(field[:target] => @event.data.fetch(field[:source]))
          end
        )
      end

      def process_update
        is_data_changed = false
        result = params[:fields_map].inject(result_hash) do |result, field|
          source = field[:source]
          target = field[:target]
          result[target] = @event.data[source]
          unless @event.data[source] == @event.prev_data[source]
            is_data_changed = true
          end

          result
        end

        return nullify_current_value unless need_translate?(@event.data)
        return no_action unless is_data_changed || !prev_version_stored?
        result_row result
      end

      def process_delete
        delete_current_value
      end

      def nullify_current_value
        result_row(
          params[:fields_map].inject(result_hash) do |result, field|
            result.merge!({field[:target] => nil})
          end
        )
      end

      def prev_version_stored?
        need_translate?(@event.prev_data)
      end

      private

      def fields_map
        @fields_map ||= params[:fields_map] || default_fields_map
      end

      def default_fields_map
        field.send(:fields_for_reset).map { |field| {:source => field, :target => field} }
      end

      def result_hash
        HashWithIndifferentAccess.new
      end
    end
  end
end
