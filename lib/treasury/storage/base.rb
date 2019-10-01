require 'callbacks_rb'

module Treasury
  module Storage
    class Base
      class_attribute :default_reset_strategy
      self.default_reset_strategy = :reset

      attr_accessor :params
      attr_reader :source

      def initialize(params)
        @callbacks = {}
        @params = default_params.deep_merge(params || {})
      end

      def bulk_write(data)
        raise NotImplementedError
      end

      def transaction_bulk_write(data)
        raise NotImplementedError
      end

      def read(object, field)
        raise NotImplementedError
      end

      # Public: Выполняет сброс данных хранилища
      #
      # object - Array or nil - Список идентификаторов объектов для сброса.
      #                         Если nil, то выполняется сброс всех объектов.
      #
      # fields - Array - Список полей для сброса.
      #
      # Returns nothing.
      def reset_data(objects, fields = nil)
        raise NotImplementedError
      end

      def start_transaction
        @transaction_started = true
      end

      def commit_transaction
        @transaction_started = false
      end

      def rollback_transaction
        @transaction_started = false
      end

      def transaction_started?
        @transaction_started
      end

      def transaction(&block)
        start_transaction
        begin
          yield
          commit_transaction
        rescue
          rollback_transaction
          raise
        end
      end

      def id
        @params[:id]
      end

      # использует ли хранилище собственное, не зависимое от основного, соединение
      # от этого зависит управление транзакцией записи данных в хранилище
      def use_own_connection?
        raise NotImplementedError
      end

      def use_processor_connection?
        !use_own_connection?
      end

      # выполняет блокировку хранилища, перед иницилизацией, если это необходимо
      def lock
      end

      def source=(source)
        @source = source
        reset_source
      end

      protected

      def default_id
        raise NotImplementedError
      end

      # Protected: Добалвяет префикс хранения полю
      #
      # field - String/Symbol - имя поля
      #
      # Returns string.

      def prepare_field(field)
        "#{@params[:fields_prefix]}#{field}"
      end

      def default_params
        {
          :id => default_id,
          :reset_strategy => default_reset_strategy
        }
      end

      def reset_source
      end

      def reset_strategy
        @params.fetch(:reset_strategy)
      end

      private

      module Batch
        def add_batch_to_processed_list(batch_id)
          raise NotImplementedError
        end

        def batch_already_processed?(batch_id)
          raise NotImplementedError
        end

        def batch_no_processed?(batch_id)
          !batch_already_processed?(batch_id)
        end

        def source_id
          source.send(:source_id)
        end
      end

      include Batch
      include CallbacksRb
    end
  end
end
