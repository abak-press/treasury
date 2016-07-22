# coding: utf-8
module Treasury
  module Fields
    # поле не требующее инициализации
    # обрабатываются только новые данные в очереди
    # очистка хранилищ не производится
    #
    # @since 0.5.0
    # @api public
    module NoRequireInitialization
      protected

      def query_rows(_offset)
        []
      end

      def lock_table(_name)
      end

      def reset_storage_data
      end
    end
  end
end
