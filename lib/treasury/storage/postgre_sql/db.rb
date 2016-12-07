# coding: utf-8

module Treasury
  module Storage
    module PostgreSQL
      # Хранилище, пишущее данные в таблицу в БД.
      #
      # Данные пишутся по столбцам, по ключевому полю
      # параметры:
      #   :table => schema.table - таблица хранилище
      #   :key   => column       - ключевое поле
      #   :db_link_class => model_class - класс соединения с БД (опционально)
      #
      # Поддерживается типизация полей.
      # Для этого в настройках поля, укажите опцию :type, например:
      #   :fields => {:domain_level => {:type => :integer}}
      # По умолчанию - все данные - строки.
      #
      class Db < Treasury::Storage::Base
        include Treasury::Storage::PostgreSQL::Base

        DEFAULT_ID = :db
        DEFAULT_SHARED = true
        BULK_WRITE_THRESHOLD = 5

        self.default_reset_strategy = :reset

        def transaction_bulk_write(data)
          transaction { bulk_write(data) }
          fire_callback(:after_transaction_bulk_write, self)
        end

        def source_table(data_rows)
          rows = data_rows.map do |object, row|
            "(#{([quote(object)] + row.map { |_field, value| quote(value) }).join(',')})"
          end

          fields = ([key] + data_rows.values.first.keys.map { |field| field }).join(',')

          <<-SQL.strip_heredoc
            (
              VALUES
                #{rows.join(',')}
            ) t (#{fields})
          SQL
        end

        def selected_fields_expression(data_rows)
          (["#{key}#{key_cast_expression}"] + data_rows.values.first.keys.map { |field| "#{field}#{field_type(field)}" }).join(',')
        end

        def matching_expression
          "target.#{key} = source.#{key}"
        end

        def updating_expression(data_rows)
          if (first_row = data_rows.values.first).present?
            first_row.keys.map { |field| "#{prepare_field(field)} = source.#{field}" }.join(',')
          else
            "#{key} = source.#{key}"
          end
        end

        def target_fields_expression(data_rows)
          (["#{key}"] + data_rows.values.first.keys.map { |field| "#{prepare_field(field)}" }).join(',')
        end

        def bulk_write(data_rows)
          if data_rows.size <= BULK_WRITE_THRESHOLD
            data_rows.each { |object, row| write(object, row) }
          else
            to_delete = data_rows.select { |object, row| row.nil? }.keys
            delete_rows(to_delete)
            data_rows.delete_if { |object, row| row.nil? }
            return unless data_rows.present?

            ::PgTools::Merge.execute(
              target_table: table_name,
              source_table: source_table(data_rows),
              selected_fields_expression: selected_fields_expression(data_rows),
              matching_expression: matching_expression,
              updating_expression: updating_expression(data_rows),
              target_fields_expression: target_fields_expression(data_rows),
              connection: connection
            )
          end
        end

        def read(object, field)
          connection.select_value <<-SQL
            SELECT "#{prepare_field(field)}"
              FROM #{table_name}
            WHERE "#{key}" = #{quote(object)}#{key_cast_expression}
          SQL
        end

        def reset_data(objects, fields)
          case reset_strategy
          when :delete
            objects.nil? ? delete_all : delete_rows(objects)
          when :reset
            reset_all(fields)
          else
            raise NotImplementedError
          end
        end

        def delete_rows(objects)
          objects = Array.wrap(objects).compact.uniq
          return 0 unless objects.present?

          object_list =
            case key_type
            when :integer
              objects.map(&:to_i).join(',')
            else
              objects.map { |object| quote(object.to_s) }.join(',')
            end

          connection.update <<-SQL
            DELETE FROM #{table_name}
              WHERE #{key} IN (#{object_list})
          SQL
        end

        def delete_all
          connection.update <<-SQL
            DELETE FROM #{table_name};
          SQL
        end

        def reset_all(fields)
          connection.execute <<-SQL
            UPDATE #{table_name}
            SET
              #{fields.map { |f| "\"#{prepare_field(f)}\" = NULL" }.join(',')}
            WHERE
              "#{key}" IS NOT NULL
          SQL
        end

        # блокирует хранилище, если оно являются разделяемыми, т.е. те,
        # в которые может вестись запись параллельно, несколькими обрабочиками разных полей.
        # в этом случае может возникнуть следующая систуация:
        # одно DB-хранилище и несколько полей привязанных к нему,
        # при инициализации одного из полей в условиях большого потока обрабатываемых событий,
        # может возникнуть ошибка: could not serialize access due to concurrent update
        def lock
          return unless shared?
          start_transaction
          connection.execute <<-SQL
            LOCK TABLE #{table_name} IN SHARE MODE
          SQL
        end

        protected

        def default_id
          DEFAULT_ID
        end

        def table_name
          connection.quote_table_name(params[:table])
        end

        def key
          params[:key]
        end

        def write(object, row)
          return delete_rows(object) if row.nil?

          data_rows = {object => row}
          ::PgTools::Merge.new(
            :target_table => table_name,
            :source_table => source_table(data_rows),
            :selected_fields_expression => selected_fields_expression(data_rows),
            :matching_expression => matching_expression,
            :updating_expression => updating_expression(data_rows),
            :target_fields_expression => target_fields_expression(data_rows),
            :connection => connection
          ).execute
        end

        # Protected: Возвращает выражения для приведения типа поля, если тип поля задан.
        #
        # Returns String.
        #
        def field_type(field)
          type = @params.fetch(:fields).try(:[], field).try(:[], :type)
          "::#{type}" unless type.blank?
        end

        # Protected: Возвращает выражения для приведения типа ключевого поля.
        #
        # Returns String.
        #
        def key_cast_expression
          "::#{key_type}"
        end

        # Protected: Возвращает тип ключевого поля.
        #
        # Returns Symbol.
        #
        def key_type
          @key_type ||= @params.fetch(:key_type, :integer).to_sym
        end

        private

        # признак является ли хранилище разделяемыми, т.е. таким,
        # которое может использоваться разными полями одновременно
        # значение данного признака устанавливается в параметрах конкретного хранилища, для конкретного поля:
        # :params => {:shared => boolean value}
        def shared?
          @params[:shared] || DEFAULT_SHARED
        end
      end
    end
  end
end
