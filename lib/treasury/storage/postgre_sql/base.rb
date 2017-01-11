# coding: utf-8

module Treasury
  module Storage
    module PostgreSQL
      # Хранилище на базе PosgreSQL.
      #
      # Может работать в 3-х режимах:
      #   - использовать "основное соединение" - то в котором работает сервис (там где хранится конфигурация);
      #   - использовать одно соединение с источником событий;
      #   - использовать свое соединение.
      #
      # По умолчанию, используется "основное соединение".
      # Соединение можно указать через параметр :db_link_class.
      # Указывается класс, исеющий метод connection (например модель ActiveRecord).
      #
      # В том случае, когда соединения хранилища и источника событий не совпадает (вариант 3)
      # - в хранилище, ведется список обработанных батчей.
      #
      # Для этого в БД хранилища, должна существовать таблица:
      #   create table denormalization.processed_batches (
      #     batch_id bigint not null,
      #     source_id character varying(32) not null,
      #     processed_at timestamp not null default NOW()
      #   )
      #
      module Base
        def start_transaction
          return if transaction_started?
          return unless storage_connection.outside_transaction?
          internal_start_transaction
          super
        end

        def commit_transaction
          return unless transaction_started?
          internal_commit_transaction
          super
        end

        def rollback_transaction
          return unless transaction_started?
          internal_rollback_transaction
          super
        end

        # Public: Использует ли хранилище собственное соединение,
        # не зависимое от соединения, в котором запрашиваются события.
        # От этого зависит управление транзакцией записи данных в хранилище.
        #
        # Returns Boolean.
        #
        def use_own_connection?
          processor_connection != storage_connection
        end

        # Public: Возвращает соединение с БД, в котором запрашиваются события.
        #
        # Returns PostgreSQLAdapter.
        #
        def processor_connection
          @processor_connection ||= source.send(:work_connection)
        end

        # Public: Возвращает соединение с БД, для работы с хранилищем
        #
        # Returns PostgreSQLAdapter.
        #
        def storage_connection
          @storage_connection ||= if params[:db_link_class].present?
            params[:db_link_class].constantize.connection
          else
            source.send(:main_connection)
          end
        end

        alias_method :connection, :storage_connection

        protected

        def reset_source
          @storage_connection = nil
          @processor_connection = nil
        end

        def internal_start_transaction
          storage_connection.begin_db_transaction
          storage_connection.increment_open_transactions
        end

        def internal_commit_transaction
          storage_connection.commit_db_transaction
          storage_connection.decrement_open_transactions
        end

        def internal_rollback_transaction
          storage_connection.rollback_db_transaction
          storage_connection.decrement_open_transactions
        end

        def quote(str)
          connection.quote(str)
        end

        module Batch
          def add_batch_to_processed_list(batch_id)
            # для хранилищ, использующих сессию процессора,
            # список обработанных батчей не ведется
            return if use_processor_connection?

            connection.execute <<-SQL
              INSERT INTO denormalization.processed_batches
              VALUES
                ( #{batch_id}, #{quote(source_id)} )
            SQL
          end

          def batch_already_processed?(batch_id)
            raise NotImplementedError if use_processor_connection?

            connection.select_value(<<-SQL).eql?('1')
              SELECT 1 FROM denormalization.processed_batches
                WHERE batch_id = #{batch_id}
                  AND source_id = #{quote(source_id)}
              LIMIT 1
            SQL
          end
        end

        include Batch
      end
    end
  end
end
