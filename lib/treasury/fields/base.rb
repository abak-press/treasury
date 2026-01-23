# frozen_string_literal: true
module Treasury
  module Fields
    class Base
      include Treasury::Utils
      include Treasury::Session
      include Treasury::Logging
      include ActiveSupport::Callbacks
      extend Apress::Sources::Accessors

      # пауза после обработки батча данных
      # позволяет снизить нагрузку на БД при инициализации,
      # за счет увеличения времени инициализации
      DEFAULT_BATCH_PAUSE = Rails.env.staging? || !Rails.env.production? ? 0 : 2.seconds

      STATE_CACHE_TTL     = 1.hour

      LOGGER_FILE_NAME = "#{ROOT_LOGGER_DIR}/field_initializer".freeze

      class_attribute :_instance

      class_attribute :initialize_method
      class_attribute :default_batch_size
      self.default_batch_size = 10_000

      self.initialize_method = :offset

      attr_accessor :batch_size
      attr_reader   :snapshot_id

      # Коллбек изменения данных поля.
      # Срабатывает после полной записи во все хранилища и после подтверждения транзакции в них.
      # Атрибут экземпляра changed_objects, содержит массив идентификаторов измененных объектов
      #
      # Example:
      #   module FieldCallback
      #     extend ActiveSupport::Concern
      #
      #     included do
      #       set_callback :data_changed, :after do |field|
      #         Apress::Companies::Sweeper.expire(field.changed_objects)
      #       end
      #     end
      #   end
      #
      #   FieldClass.send(:include, FieldCallback)
      #
      define_callbacks :data_changed

      def self.raise_no_implemented(accessor_type, params)
        raise Treasury::Fields::Errors::NoAccessor.new(self, accessor_type, params)
      end

      def self.create_by_class(klass, field_model = Treasury::Models::Field.find_by_field_class(klass.to_s))
        raise Errors::UnknownFieldClassError if field_model.nil?

        return klass.to_s.constantize.new(field_model)
      rescue => e
        log_error(e)
        raise
      end

      def self.instance
        # TODO: нужно будет придумать механизм инвалидации инстанса при изменении параметров хранилища и т.п.
        self._instance ||= create_by_class(self)
      end

      def initialize(field_model)
        @process_object = field_model
        init_params
      end

      def init_params
        @batch_size = field_params.fetch(:batch_size, self.class.default_batch_size)
        @batch_pause = DEFAULT_BATCH_PAUSE
      end

      def initialize!
        logger.info "Процесс иницилизации поля #{quote(field_model.title)} запущен"
        return unless check_active
        return unless check_terminate
        return unless check_need_initialize
        return unless check_processors

        set_state(STATE_IN_INITIALIZE)
        clear_last_error
        subscribe_all_consumer
        reset_storage_data
        initialize_field
      rescue => e
        log_error(e)
        set_state(STATE_NEED_INITIALIZE) rescue nil
        raise
      ensure
        logger.info "Процесс иницилизации поля остановлен"
      end

      def storages
        @storages ||= storages_hash.values
      end

      # Public: Возвращает Storage-объекты с идентификатором из переданного множества
      #
      # ids - Array of Symbols, массив идентификаторов хранилищ
      #
      # Returns Array of Storage
      def storages_by_ids(ids)
        storages.select { |storage| ids.include?(storage.id) }
      end

      def default_storage
        storages.first
      end

      def write_data(data, force = false)
        return if data.empty?

        storages.each do |storage|
          storage.transaction_bulk_write(data) if force || !storage.params[:write_only_processed]
        end
      end

      def field_model
        @process_object
      end

      def first_field
        # params[:fields] - хэш полей и их параметров
        # каждый элемент хэш: field => {params}
        @first_field ||= field_params[:fields].keys.first.to_sym
      end

      # Public: Возвращает значение поля.
      #
      # object  - String или Integer идентификатор объекта, для которого запрашивается значение.
      # field   - String или Symbol идентификатор поля, значение которого запрашивается.
      #           Не обязательный параметр. По умолчанию - первое поле.
      # storage - String или Symbol идентификатор хранилища, из которого нужно получить значение
      #           Не обязательный параметр. По умолчанию - хранилище по умолчанию.
      #
      # Examples:
      #   Apress::AwesomeField.raw_value(user.id, :products_count)
      #   # => 10
      #
      # Returns значение поля. Тип зависит от реализации конкретного хранилища.
      # Raises UninitializedFieldError, если поле не инициализировано.

      def raw_value(object, field = nil, storage = nil)
        raise Errors::UninitializedFieldError unless cached_state == STATE_INITIALIZED

        raw_value_from_storage object, field, storage
      end

      # Public: Проверяет инициализировано поле или нет.
      #         Если нет, возвращает nil. Если да, возвращает значение поля.
      # Returns
      #   Значение поля - если инициализировано
      #   nil - если не инициализировано
      def raw_value?(object, field = nil, storage = nil)
        return unless cached_state == STATE_INITIALIZED

        raw_value_from_storage object, field, storage
      end

      def reset_field_value(field_name)
        reset_storage_data([field_name])
      end

      protected

      attr_reader :changed_objects

      def self.value
        raw_value(@accessing_object, @accessing_field)
      end

      def raw_value_from_storage(object, field = nil, storage = nil)
        storage = storages_hash[storage || default_storage.id]
        field ||= first_field
        storage.read(object, field)
      end

      def fields_for_reset
        field_params[:fields].keys
      end

      def reset_storage_data(fields = [])
        storages.each do |storage|
          logger.info "Сбрасываю данные хранилища #{storage.id}"
          storage.reset_data(objects_for_reset, fields.empty? ? fields_for_reset : fields)
        end
      end

      # Protected: Возвращает список идентификаторов объектов для сброса.
      #
      # Если доступен метод reset_statement, то выполняет запрос и возвращает список объектов,
      # иначе возвращает nil.
      #
      # Returns Array or nil.
      #
      def objects_for_reset
        return nil unless respond_to?(:reset_statement, true)

        logger.info "Запрашиваю список объектов для сброса:\r\n #{reset_statement}"
        work_connection.select_values(reset_statement)
      end

      def initialize_field
        logger.info "Стартую spanshot-транзакцию"

        main_connection.transaction do
          work_connection.transaction do
            lock_storages

            @snapshot_id = start_snapshot

            before_initialize

            @total_rows = 0

            case self.class.initialize_method
            when :offset then offset_initialize
            when :interval then interval_initialize
            else raise 'Unknown initialize method'
            end

            save_snapshot
            set_state(STATE_INITIALIZED)

            after_initialize
          end
        end
      end

      # Офсетная иниализация
      def offset_initialize
        step = 0
        while true
          exit unless check_terminate

          step += 1
          offset = (step - 1) * batch_size

          count_rows = fetch_rows(:query_args => {:offset => offset, :limit => batch_size})

          break if count_rows < batch_size
        end
      end

      # Интервальная инициализация
      def interval_initialize
        min_id, max_id = work_connection.select_one(interval_statement).values.map(&:to_i)
        return if min_id.nil? || max_id.nil?

        logger.info "min_id = #{min_id}, max_id = #{max_id}, ~ count = #{max_id - min_id}"

        while min_id <= max_id
          exit unless check_terminate

          next_id = min_id + batch_size - 1
          fetch_rows(:query_args => {:min_id => min_id, :max_id => next_id})
          min_id = next_id + 1
        end
      end

      # Затянуть строчки для обработки
      #
      # options - Hash
      #           :query_args - Hash
      #
      # Return Integer size of fetched rows
      def fetch_rows(options)
        before_batch_process
        rows = query_rows(options[:query_args])
        after_batch_process

        @total_rows += rows.size

        write_data(process_rows(rows)) unless rows.count.zero?
        save_progress(@total_rows)

        sleep(@batch_pause)

        rows.size
      end

      # Запрос на получение срочек
      #
      # query_args - Hash
      #
      # Returns Array
      def query_rows(query_args)
        query = initialize_statement % query_args
        logger.info "Выполняю запрос:\r\n %s" % query
        work_connection.select_all(query).map do |row|
          HashWithIndifferentAccess.new(row)
        end
      end

      def process_rows(rows)
        rows.inject(HashWithIndifferentAccess.new) do |hash, row|
          hash.merge!(row[:object_id] => row.except(:object_id))
        end
      end

      def initialize_statement
        raise NotImplementedError
      end

      def start_snapshot
        work_connection.execute <<-SQL
          SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        SQL

        work_connection.select_value <<-SQL
          SELECT txid_current_snapshot();
        SQL
      end

      def lock_storages
        logger.info "Лочу хранилища"
        storages.each(&:lock)
      end

      def before_initialize
        return unless defined?(prepare_data_block)

        logger.info "Выполняю блок подготовки данных:\r\n %s" % prepare_data_block
        work_connection.execute(prepare_data_block)
      end

      # Protected: Выполняет блок финализации данных, если он задан.
      #
      # * Выполняется только в случае успешной инициализации.
      #
      # Returns nothing.

      def after_initialize
        return unless defined?(finalize_data_block)

        logger.info "Выполняю блок финализации данных:\r\n %s" % finalize_data_block
        work_connection.execute(finalize_data_block)
      end

      def before_batch_process
        return unless defined?(prepare_batch_data_block)

        logger.info "Выполняю блок подготовки пачки:\r\n %s" % prepare_batch_data_block
        work_connection.execute(prepare_batch_data_block)
      end

      # Protected: Выполняет блок финализации данных пачки, если он задан.
      #
      # * Выполняется только в случае успешной обработки порции данных.
      #
      # Returns nothing.

      def after_batch_process
        return unless defined?(finalize_batch_data_block)

        logger.info "Выполняю блок финализации пачки:\r\n %s" % finalize_batch_data_block
        work_connection.execute(finalize_batch_data_block)
      end

      def lock_table(processor)
        table_name = processor.queue.table_name
        return if table_name.nil? || table_name.empty?

        logger.info "Лочу таблицу #{table_name}"
        work_connection.execute <<-SQL
          LOCK TABLE #{table_name} IN SHARE MODE
        SQL
      end

      def subscribe_all_consumer
        work_connection.transaction do
          field_model.processors.each do |processor|
            logger.info "Иницилизация процессора %s" % processor.processor_class
            lock_table(processor)
            logger.info "Подписываюсь на события"
            processor.subscribe!
          end
        end
      end

      def save_snapshot
        field_model.snapshot_id = @snapshot_id
        field_model.save!
      end

      def save_progress(rows_processed)
        logger.info "Обработано строк: #{rows_processed}"
      end

      def check_active
        return true if field_model.active?

        logger.warn "Поле не активно"
        false
      end

      def check_need_initialize
        return true if check_state(STATE_NEED_INITIALIZE)
        return true if check_state(STATE_IN_INITIALIZE) && process_is_dead?(field_model.pid)

        logger.warn "Поле не требует иницилизации"
        false
      end

      def check_processors
        return true if field_model.processors.exists?

        logger.warn "Поле не имеет не одного процессора"
        false
      end

      # Public: Возвращает значение поля.
      #
      # See InstanceMethods#raw_value
      #
      # Returns значение поля.
      def self.raw_value(object, field = nil, storage = nil)
        @silence ? instance.raw_value?(object, field, storage) : instance.raw_value(object, field, storage)
      end

      def self.logger_default_file_name
        LOGGER_FILE_NAME
      end

      def quote(str)
        ::ActiveRecord::Base.connection.quote(str)
      end

      def self.extract_object(params)
        raise NotImplementedError
      end

      def self.init_accessor(params)
        @accessing_object = extract_object(params)
        @accessing_field  = params[:field]
        @silence = params.fetch(:silence, false)
      end

      def self.accessing_object
        @accessing_object
      end

      def self.accessing_field
        @accessing_field
      end

      def data_changed(changed_objects)
        @changed_objects = changed_objects
        run_callbacks :data_changed
      end

      # Public: Рабочее соединение с БД для данной очереди.
      #
      # В рамках этого соединения производятся все действия с объектами привязанными к данной очереди,
      # а именно инициализация и обработка событий.
      #
      # Returns ActiveRecord::ConnectionAdapters::AbstractAdapter.
      #
      def work_connection
        @work_connection ||= field_model.processors.first.queue.work_connection
      end

      # Public: Основное соединение с БД.
      #
      # В рамках этого соединения производятся общие действия (изменения метаданных).
      #
      # Returns ActiveRecord::ConnectionAdapters::AbstractAdapter.
      #
      def main_connection
        ActiveRecord::Base.connection
      end

      # Public: Перзапись объекта
      #
      # Должно быть перекрыто для нужного поля.
      #
      def self.reinitialize_object(object_id)
        raise NotImplementedError
      end

      private

      attr_accessor :state_updated_at

      # Private: Возвращает хранилища поля.
      #
      # * У поля может быть несколько хранилищ.
      #   field.storage - это массив хэшей вида: {:class, :id, :params}
      # * Хранилище по умолчанию - первое хранилище
      #
      # Returns HashWithIndifferentAccess всех хранилищ поля.
      #   Каждый элемент хэша - это экземпляр хранилища.
      #   {storage_id => storage_instance}

      def storages_hash
        @storages_hash ||= field_model.storage.inject(HashWithIndifferentAccess.new) do |hash, storage|
          params = storage.fetch(:params, Hash.new)
          params[:id] = storage[:id] if storage[:id]
          params.reverse_merge!(storage_params)

          storage = storage[:class].constantize.new(params)
          storage.source = self
          hash.merge!(storage.id => storage)
        end
      end

      def storage_params
        params = {
          :fields => field_params[:fields],
          :fields_prefix => fields_storage_prefix
        }

        params[:reset_strategy] = field_params[:reset_strategy] if field_params.key?(:reset_strategy)
        params
      end

      # Private: Возвращает кэшированное состояние поля.
      #
      # * Состояние поле кэшируется на время STATE_CACHE_TTL
      #
      # Returns Fields::STATES*.

      def cached_state
        if @state_updated_at.nil? || (Time.now - @state_updated_at >= STATE_CACHE_TTL)
          @state_updated_at = Time.now
          refresh_state
        end

        field_model.state
      end

      # Private: Возвращает параметры Поля.
      #
      # Returns Hash.

      def field_params
        (field_model.params || {}).with_indifferent_access
      end

      # Private: Возвращает префикс хранения для полей.
      #
      # Returns String.

      def fields_storage_prefix
        prefix = field_params[:fields_storage_prefix]
        return if prefix.nil? || prefix.empty?

        "#{prefix}_"
      end
    end
  end
end
