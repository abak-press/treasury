describe ::Treasury::Processors::Base do
  # TODO: дописать тесты
  # нужно дописать тесты методов:
  #   batch_already_processed?
  #   get_batch_events
  #   проверить что доступна @fetch_size и используется в get_batch_events
  #   process
  #
  # нужно написать интеграционный тест, которы йпроверит все цепочку от PGQ до Redis

  class TestConsumer < Treasury::Processors::Base
    def get_batch_events
      @events_batches.each { |batch| yield batch }
    end

    def form_value(value)
      {:field => value}
    end
  end

  BATCH_ID = 1
  # EVENTS_BATCHES_EMPTY = []
  EVENTS_BATCHES_TEST  = [[1, 2, 3], [4], [2, 6]]

  let(:queue) { build 'denormalization/queue' }
  let(:processor) { build 'denormalization/processor', queue: queue }
  let(:consumer) { TestConsumer.new(processor) }

  subject { consumer }

  context 'метод write_data' do
    it 'не должен ничего писать, если буфер пуст' do
      data = []

      storages = 2.times.map do
        storage = Object.new
        expect(storage).not_to receive(:bulk_write).with(data)
        storage
      end

      subject.instance_variable_set(:@data, data)

      allow(consumer).to receive(:storages).and_return(storages)
      subject.send(:write_data)
    end

    it 'должен для каждого хранилища выполнить методы start_transaction и bulk_write' do
      data = [1, 2, 3]

      storages = 2.times.map do
        storage = Object.new
        expect(storage).to receive(:bulk_write).with(data)
        storage
      end

      subject.instance_variable_set(:@data, data)

      allow(consumer).to receive(:storages).and_return(storages)
      subject.send(:write_data)
    end
  end

  context 'метод commit_storage_transaction' do
    it 'должен для каждого хранилища выполнить методы add_batch_to_processed_list и commit_transaction' do
      batch_id = rand(100)
      storages = 2.times.map do
        storage = Object.new
        expect(storage).to receive(:add_batch_to_processed_list).with(batch_id)
        expect(storage).to receive(:commit_transaction)
        storage
      end
      allow(consumer).to receive(:storages).and_return(storages)

      subject.instance_variable_set(:@batch_id, batch_id)

      subject.send(:commit_storage_transaction)
    end
  end

  context 'метод reset_buffer' do
    it 'должен очищать буфер' do
      subject.instance_variable_set(:@data, [1, 2, 3])
      subject.send(:reset_buffer)
      expect(subject.instance_variable_get(:@data).size).to eq(0)
    end
  end

  context 'метод finish_batch' do
    it 'должен вызывать метод API PGQ finish_batch с вернымыми параметрами' do
      batch_id = rand(100)
      subject.instance_variable_set(:@batch_id, batch_id)
      expect(ActiveRecord::Base).to receive(:pgq_finish_batch).with(batch_id, subject.send(:work_connection))
      subject.send(:finish_batch)
    end
  end

  context 'метод interesting_event?' do
    it 'должен опеределять интересные/не интересные события' do
      event_txid = rand(100)
      subject.event.txid = event_txid
      enteresting = rand(2).to_s.to_b
      snapshot = subject.instance_variable_get(:@snapshot)
      expect(snapshot).to receive(:contains?).with(event_txid).and_return(enteresting)
      expect(subject.send(:interesting_event?)).to be !enteresting
    end
  end

  context 'метод get_batch' do
    it 'должен вызывать метод API pgq_next_batch и устанавливать корректный @batch_id' do
      batch_id = rand(100)
      expect(ActiveRecord::Base).to(
        receive(:pgq_next_batch)
          .with(subject.queue_name, subject.consumer_name, subject.send(:work_connection))
          .and_return(batch_id)
      )

      subject.send(:get_batch)
      expect(subject.instance_variable_get(:@batch_id)).to be batch_id
    end

    it 'должен вызывать метод API pgq_next_batch и получать исключение Treasury::Pgq::Errors::QueueOrSubscriberNotFoundError, если не найдена очередь или консьюмер' do
      allow(ActiveRecord::Base).to(
        receive(:pgq_next_batch)
          .and_raise(ActiveRecord::StatementInvalid.new('Not subscriber to queue'))
      )

      expect { subject.send(:get_batch) }.to raise_error(Treasury::Pgq::Errors::QueueOrSubscriberNotFoundError)
    end

    it 'должен вызывать метод API pgq_next_batch и транслировать родительское исключение, если не обработано' do
      allow(ActiveRecord::Base).to receive(:pgq_next_batch).and_raise(ActiveRecord::StatementInvalid.new(''))
      expect { subject.send(:get_batch) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  context 'метод process_events_batch' do
    it 'должен вызывать метод обработки каждого события' do
      events = rand(100).times.map { rand(100) }
      events.each { |event| expect(subject).to receive(:internal_process_event).with(event).ordered }
      subject.send(:process_events_batch, events)
    end
  end

  context 'метод internal_process_event' do
    let(:event) { {rand(100) => rand(100)} }

    it 'должен ничего не делать и вернуть nil, если событие не интересно' do
      subject.instance_variable_set(:@data, event)
      allow(consumer).to receive(:interesting_event?).and_return(false)
      allow(consumer.event).to receive(:assign)
      expect(subject.send(:internal_process_event, {})).to be_nil
      expect(subject.instance_variable_get(:@data)).to be event
    end

    it 'не должен записывать в буфер данные, если результат обработки события nil' do
      subject.instance_variable_set(:@data, event)
      allow(consumer).to receive(:interesting_event?).and_return(true)
      allow(consumer.event).to receive(:assign)
      allow(subject).to receive(:process_event).and_return(nil)
      expect(subject.instance_variable_get(:@data)).to be event
    end

    it 'должен корректно обрабатывать событие' do
      subject.instance_variable_set(:@data, {})
      expect(subject.event).to receive(:assign).with(event).ordered
      expect(subject).to receive(:interesting_event?).ordered.and_return(true)
      expect(subject).to receive(:init_event_params).ordered
      expect(subject).to receive(:process_event).ordered.and_return(event)

      subject.send(:internal_process_event, event)
      expect(subject.instance_variable_get(:@data)).to eq event
    end

    context 'должен записывать все изменёные поля для нескольких событий' do
      let(:event_1) { {'1' => {a: 1, b: 1}} }
      let(:event_2) { {'1' => {b: 2}} }

      before do
        subject.instance_variable_set(:@data, {})
        allow(subject).to receive(:interesting_event?).and_return(true)
        allow(subject).to receive(:init_event_params)
        allow(subject.event).to receive(:assign)
      end

      it do
        expect(subject).to receive(:process_event).and_return(event_1)
        subject.send(:internal_process_event, event_1)
        expect(subject).to receive(:process_event).and_return(event_2)
        subject.send(:internal_process_event, event_2)

        expect(subject.instance_variable_get(:@data)).to eq('1' => {a: 1, b: 2})
      end
    end
  end

  context 'метод storages' do
    it 'должен возвращать field.storages' do
      storages = rand(100).times.map { rand(100) }
      allow(subject).to receive_message_chain("field.storages").and_return(storages)
      expect(subject.send(:storages)).to eq storages
    end
  end

  context 'метод field_class' do
    it 'должен возвращать field.storages' do
      expect(subject.send(:field_class)).to eq processor.field.field_class
    end
  end

  context 'метод field' do
    it 'должен возвращать экземпляр processor.field.field_class' do
      expect(subject.send(:field)).to be_an_instance_of processor.field.field_class.constantize
    end
  end

  context 'при создании класса должен быть проиницилизирован экземпляр @event' do
    it { expect(subject.event).to be_an_instance_of Treasury::Pgq::Event }
  end

  context 'при создании класса должен быть проиницилизирован экземпляр @event' do
    it { expect(subject.instance_variable_get(:@snapshot)).to be_an_instance_of Treasury::Pgq::Snapshot }
  end

  context 'интерфейс класса' do
    it 'методы обработки событий должны генерировать исключения' do
      expect { subject.send(:process_insert) }.to raise_error(NotImplementedError)
      expect { subject.send(:process_update) }.to raise_error(NotImplementedError)
      expect { subject.send(:process_delete) }.to raise_error(NotImplementedError)
    end

    context 'метод process_event' do
      it 'должен генерировать исключение, при обработке события, неизвестного типа' do
        expect { subject.send(:process_event) }.to raise_error(Treasury::Processors::Errors::UnknownEventTypeError)
      end

      it 'должен выполнить метод process_insert, при обработке события, с типом INSERT' do
        expect(subject.event).to receive(:type).and_return(Treasury::Pgq::Event::TYPE_INSERT)
        expect(subject).to receive(:process_insert)
        expect(subject).not_to receive(:process_update)
        expect(subject).not_to receive(:process_delete)
        subject.send(:process_event)
      end

      it 'должен выполнить метод process_update, при обработке события, с типом UPDATE, если данные изменились' do
        expect(subject.event).to receive(:type).and_return(Treasury::Pgq::Event::TYPE_UPDATE)
        expect(subject.event).to receive(:data_changed?).and_return(true)
        expect(subject).not_to receive(:process_insert)
        expect(subject).to receive(:process_update)
        expect(subject).not_to receive(:process_delete)
        subject.send(:process_event)
      end

      it 'не должен выполнить метод process_update, при обработке события, с типом UPDATE, если данные не изменились' do
        expect(subject.event).to receive(:type).and_return(Treasury::Pgq::Event::TYPE_UPDATE)
        expect(subject).not_to receive(:process_insert)
        expect(subject).not_to receive(:process_update)
        expect(subject).not_to receive(:process_delete)
        subject.send(:process_event)
      end

      it 'должен выполнить метод process_update, при обработке события, с типом DELETE' do
        expect(subject.event).to receive(:type).and_return(Treasury::Pgq::Event::TYPE_DELETE)
        expect(subject).not_to receive(:process_insert)
        expect(subject).not_to receive(:process_update)
        expect(subject).to receive(:process_delete)
        subject.send(:process_event)
      end
    end

    context 'метод init_params' do
      it 'должен выполняться при создании объекта' do
        expect_any_instance_of(TestConsumer).to receive(:init_params)
        TestConsumer.new(processor)
      end

      it 'должен заполнять параметры процессора' do
        expect(subject.params).to eq processor.params || HashWithIndifferentAccess.new
        expect(subject.instance_variable_get(:@params)).to eq processor.params || HashWithIndifferentAccess.new
      end
    end

    context 'метод nullify_current_value' do
      it 'должен корректно работать' do
        expect(subject.send(:nullify_current_value)).to eq subject.send(:result_row, nil)
      end
    end

    context '#delete_current_row' do
      let(:delete_current_row) { consumer.send(:delete_current_row) }

      it { expect(delete_current_row).to eq(subject.object => nil) }
    end

    context '#delete_current_value' do
      let(:delete_current_value) { consumer.send(:delete_current_value) }

      context 'when processor is master' do
        before { processor.params = {:master => true} }

        it { expect(delete_current_value).to eq(consumer.object => nil) }
      end

      context 'when processor is not master' do
        before { processor.params = {:master => false} }

        it { expect(delete_current_value).to eq consumer.send(:result_row, nil) }
      end
    end

    context 'метод no_action' do
      it { expect(subject.send(:no_action)).to be_nil }
    end

    context 'метод form_value' do
      value = rand(100)
      it { expect(subject.send(:form_value, value)).to eq(:field => value) }
    end

    context 'метод result_row' do
      it 'должен корректно работать' do
        value = rand(100)
        object = rand(100)
        subject.instance_variable_set(:@object, object)
        expect(subject.send(:result_row, value)).to eq(object => {:field => value})
      end
    end

    context 'метод current_value' do
      let(:field_value) { rand(100) }
      let(:value) { {field: (field_value + 1), field2: (field_value + 2)} }
      let(:object) { rand(100) }

      before do
        subject.instance_variable_set(:@object, object)
        subject.instance_variable_set(:@data, object => value)
      end

      it 'должен читать значение из хранилища, если данных нет в буфере' do
        subject.instance_variable_set(:@object, object + 1)
        subject.send(:field).should_receive(:raw_value).and_return(field_value)
        subject.send(:current_value, :field).should eq field_value
      end

      it 'должен читать значение из хранилища, если поля нет в буфере' do
        expect(subject.send(:field)).to receive(:raw_value).with(object, :field3).and_return(field_value)
        expect(subject.send(:current_value, :field3)).to eq field_value
      end

      it 'должен читать данные из буфера, если они там есть' do
        expect(subject.send(:current_value, :field2)).to eq(value[:field2])
      end

      context 'если поле не указанно' do
        it 'должен возвращать значение первого поля, если оно есть в буфере' do
          expect(subject.send(:field)).to receive(:first_field).at_least(:once).and_return(:field)
          expect(subject.send(:current_value)).to eq value[:field]
        end

        it 'должен читать значение из хранилища, если поля нет в буфере' do
          expect(subject.send(:field)).to receive(:first_field).at_least(:once).and_return(:field3)
          expect(subject.send(:field)).to receive(:raw_value).with(object, nil).and_return(field_value)
          expect(subject.send(:current_value)).to eq field_value
        end
      end
    end

    context 'метод current_value_as_integer' do
      it 'должен вызывать current_value с полем, если поле указано' do
        field = :field
        expect(subject).to receive(:current_value).with(field)
        subject.send(:current_value_as_integer, field)
      end

      it 'должен вызывать current_value с nil, если поле не указано' do
        expect(subject).to receive(:current_value).with(nil)
        subject.send(:current_value_as_integer)
      end

      it 'должен возвращать правильный результат' do
        value = rand(100)
        allow(subject).to receive(:current_value).and_return(value.to_s)
        expect(subject.send(:current_value_as_integer)).to eq value
      end
    end

    context 'метод incremented_current_value' do
      it 'должен вызывать current_value_as_integer с полем, если поле указано' do
        field = :field
        expect(subject).to receive(:current_value_as_integer).with(field).and_return(0)
        subject.send(:incremented_current_value, field)
      end

      it 'должен вызывать current_value_as_integer с nil, если поле не указано' do
        expect(subject).to receive(:current_value_as_integer).with(nil).and_return(0)
        subject.send(:incremented_current_value)
      end

      it 'должен возвращать правильный результат' do
        value = rand(100)
        allow(subject).to receive(:current_value_as_integer).and_return(value)
        expect(subject.send(:incremented_current_value)).to eq value.succ
      end
    end

    context 'метод decremented_current_value' do
      it 'должен вызывать current_value_as_integer с полем, если поле указано' do
        field = :field
        expect(subject).to receive(:current_value_as_integer).with(field).and_return(0)
        subject.send(:decremented_current_value, field)
      end

      it 'должен вызывать current_value_as_integer с nil, если поле не указано' do
        expect(subject).to receive(:current_value_as_integer).with(nil).and_return(0)
        subject.send(:decremented_current_value)
      end

      it 'должен возвращать правильный результат' do
        value = rand(100)
        allow(subject).to receive(:current_value_as_integer).and_return(value)
        expect(subject.send(:decremented_current_value)).to eq value.pred
      end
    end

    # перенести в processors::single spec
    #context 'метод increment_current_value' do
    #  let(:value) { {:field => rand(100), :field2 => rand(100)} }
    #  let(:object) { rand(100) }
    #
    #  before do
    #    subject.instance_variable_set(:@object, object)
    #  end
    #
    #  it 'должен корректно работать при вызове с указанием поля' do
    #    subject.send(:increment_current_value, :field2).should eq subject.send(:result_row, value.merge(:field2 => value[:field2].next))
    #  end
    #end
  end

  # FIXME: тесты ужасны, они проверяют реализацию, а не результат, любой рефакторинг окажется самым страшным адом.
  describe '#process' do
    let(:process) { subject.process }

    it 'должен получить следующий необработанный батч, если батча нет, ничего не делать' do
      expect(ActiveRecord::Base).to receive(:pgq_next_batch).and_return(nil)
      expect(subject).to_not receive(:start_storage_transaction)
      expect(subject).not_to receive(:commit_storage_transaction)
      expect(subject).not_to receive(:finish_batch)
      expect(process).to eq(:events_processed => 0, :rows_written => 0)
    end

    context 'если есть батч' do
      before do
        allow(ActiveRecord::Base).to receive(:pgq_next_batch).and_return(BATCH_ID)
        allow(subject).to receive(:process_events_batch) do |events|
          data = subject.instance_variable_get(:@data)
          subject.instance_variable_set(:@data, data.merge(events.inject({}) { |r, id| r.merge(id => 1) }))
        end
        subject.instance_variable_set(:@events_batches, EVENTS_BATCHES_TEST)
      end

      context 'и батч не пустой' do
        context 'when called' do
          let(:storages) { [double('storage1'), double('storage2')] }

          before { allow(consumer).to receive(:storages).and_return(storages) }

          after { process }

          # порядок выполнения методов должен быть верным и колбеки должны вызываться в верном порядке
          it do
            expect(subject).to receive(:before_batch_processing).ordered
            storages.each { |storage| expect(storage).to receive(:source=).with(subject) }
            storages.each { |storage| expect(storage).to receive(:start_transaction) }
            EVENTS_BATCHES_TEST.each { |batch| expect(subject).to receive(:process_events_batch).with(batch).ordered }
            expect(subject).to receive(:write_data).ordered
            expect(subject).to receive(:after_batch_processing).ordered
            expect(subject).to receive(:commit_storage_transaction).ordered
            expect(subject).to receive(:finish_batch).ordered
            expect(subject).to receive(:data_changed).ordered
          end
        end

        context 'after call' do
          before do
            allow(subject).to receive(:commit_storage_transaction)
            allow(subject).to receive(:finish_batch)
            process
          end

          it 'метод должен вернуть корректное кол-во обработанных событий' do
            expect(process).to eq(:events_processed => 6, :rows_written => 5)
          end

          it 'должен верно формировать список измененных объектов' do
            expect(subject.instance_variable_get(:@changed_keys)).to eq EVENTS_BATCHES_TEST.flatten.uniq
          end
        end
      end

      context 'и батч не пустой' do
        before { allow(subject).to receive(:finish_batch) }

        it 'то для каждого батча должен быть вызван метод обработки' do
          EVENTS_BATCHES_TEST.each { |batch| subject.should_receive(:process_events_batch).with(batch) }
          subject.process
        end

        it 'метод должен вернуть корректное кол-во обработанных событий' do
          subject.process.should == {events_processed: EVENTS_BATCHES_TEST.flatten.size, rows_written: 5}
        end
      end
    end
  end

  context '#data_changed' do
    before { subject.instance_variable_set(:@changed_keys, [1, 2, 3]) }

    context 'when changed objects list is empty' do
      before { subject.instance_variable_set(:@changed_keys, []) }

      it do
        expect(subject.send(:field)).not_to receive(:data_changed)
        subject.send(:data_changed)
      end
    end

    context 'when changed objects list is not empty' do
      it do
        expect(subject.send(:field)).to receive(:data_changed).with([1, 2, 3])
        subject.send(:data_changed)
      end
    end

    context 'when exception in callbacks' do
      before { allow(subject.send(:field)).to receive(:data_changed).and_raise(StandardError) }
      it { expect { subject.send(:data_changed) }.to_not raise_error }
    end
  end

  describe '#object_value' do
    let(:object) { '2000' }
    let(:data) do
      {
        '1000' => {count1: '50', count2: '100'},
        '2000' => {count1: '550', count2: '600'}
      }
    end
    let(:field) { double first_field: :count1 }

    before do
      subject.instance_variable_set(:@data, data)
      subject.instance_variable_set(:@object, object)

      allow(field).to receive(:raw_value).with('3000', :count2).and_return('1050')
      allow(subject).to receive(:field).and_return(field)

      allow(subject).to receive(:log_event)
    end

    it :aggregate_failures do
      expect(subject.object_value('1000', :count2)).to eq '100'
      expect(subject.object_value('1000')).to eq '50'
      expect(subject.object_value('2000')).to eq '550'
      expect(subject.object_value('3000', :count2)).to eq '1050'
    end
  end
end
