module Treasury
  module Processors
    # процессор - оптимизированный транслятор данных
    # транслирует данные поступающие в очередь - в хранилище
    # отличие от обычного транслятора:
    # в результирующем хэше, возвращает только измененные поля
    # из-за этого, его нельзя использовать, с некоторыми типами хранилищ
    module OptimizedTranslator
      include Treasury::Processors::Translator

      protected

      def process_update
        is_prev_version_stored = prev_version_stored?
        is_data_changed = false

        fields_result = fields_map.inject(result_hash) do |result, field|
          source = field[:source]
          target = field[:target]
          if (@event.data[source] == @event.prev_data[source]) && is_prev_version_stored
            result
          else
            is_data_changed = true
            result.merge!(target => @event.data[source])
          end
        end

        return nullify_current_value unless need_translate?(@event.data)
        return no_action unless is_data_changed
        result_row fields_result
      end
    end
  end
end
