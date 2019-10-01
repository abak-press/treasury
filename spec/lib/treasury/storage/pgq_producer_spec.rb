class ProcessorClass
end

describe Treasury::Storage::PostgreSQL::PgqProducer do
  let(:options) { {queue: 'queue', key: 'key'} }
  let(:storage) { described_class.new(options) }
  let(:event_type) { "#{Treasury::Pgq::Event::TYPE_INSERT}:id" }
  let(:data) do
    {
      object1: {field1: :value1, field2: :value2},
      object2: {field11: :value11, field22: :value22}
    }
  end

  subject { storage }

  context do
    before do
      allow(storage).to receive(:start_transaction)
      allow(storage).to receive(:storage_connection).and_return(ActiveRecord::Base)
      allow(storage).to receive(:source).and_return(ProcessorClass.new)
      allow(ActiveRecord::Base).to receive(:pgq_insert_event)
      expect(ActiveRecord::Base).to(
        receive(:pgq_insert_event).with(
          'queue',
          event_type,
          'key=object1&_processor_id_=ProcessorClass&field1=value1&field2=value2'
        )
      )
      expect(ActiveRecord::Base).to(
        receive(:pgq_insert_event).with(
          'queue',
          event_type,
          'key=object2&_processor_id_=ProcessorClass&field11=value11&field22=value22'
        )
      )
    end

    it '#bulk_write' do
      subject.bulk_write(data)
    end

    it '#transaction_bulk_write' do
      subject.transaction_bulk_write(data)
    end
  end
end
