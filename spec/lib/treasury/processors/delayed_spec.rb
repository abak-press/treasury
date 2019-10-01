class TestConsumer < Treasury::Processors::Base
  include Treasury::Processors::Delayed
end

describe Treasury::Processors::Delayed do
  let(:queue) { FactoryGirl.build 'denormalization/queue' }
  let(:processor) { FactoryGirl.build 'denormalization/processor', queue: queue }
  let(:consumer) { TestConsumer.new(processor) }

  before do
    consumer.event.data[:id] = double('id')
    consumer.object = double('object')
  end

  describe '#delayed_increment_current_value' do
    let(:delayed_increment_current_value) { consumer.delayed_increment_current_value(:field_name, 48.hours) }

    context 'when call' do
      after { delayed_increment_current_value }

      it do
        expect(Resque).to receive(:enqueue_in).with(
          48.hours,
          Treasury::DelayedIncrementJob,
          id: consumer.event.data[:id],
          object: consumer.object,
          field_class: consumer.send(:field_class),
          field_name: :field_name,
          by: 1
        )
      end
    end

    it { expect(delayed_increment_current_value).to eq consumer.send(:no_action) }
  end

  describe '#cancel_delayed_increment' do
    context 'when call' do
      after { consumer.cancel_delayed_increment(:field_name) }

      it do
        expect(Resque).to receive(:remove_delayed).with(
          Treasury::DelayedIncrementJob,
          id: consumer.event.data[:id],
          object: consumer.object,
          field_class: consumer.send(:field_class),
          field_name: :field_name,
          by: 1
        ).and_return 0
      end
    end

    context 'when removed job exists' do
      before { allow(Resque).to receive(:remove_delayed).and_return 1 }

      it { expect(consumer.cancel_delayed_increment(:field_name)).to be_truthy }
    end

    context 'when removed job not exists' do
      before { allow(Resque).to receive(:remove_delayed).and_return 0 }

      it { expect(consumer.cancel_delayed_increment(:field_name)).to be_falsey }
    end
  end

  describe '#delayed_decrement_current_value' do
    let(:delayed_decrement_current_value) { consumer.delayed_decrement_current_value(:field_name, 48.hours) }

    context 'when call' do
      after { delayed_decrement_current_value }

      it do
        expect(Resque).to receive(:enqueue_in).with(
          48.hours,
          Treasury::DelayedIncrementJob,
          id: consumer.event.data[:id],
          object: consumer.object,
          field_class: consumer.send(:field_class),
          field_name: :field_name,
          by: -1
        )
      end
    end

    it { expect(delayed_decrement_current_value).to eq consumer.send(:no_action) }
  end

  describe '#cancel_delayed_decrement' do
    context 'when call' do
      after { consumer.cancel_delayed_decrement(:field_name) }

      it do
        expect(Resque).to receive(:remove_delayed).with(
          Treasury::DelayedIncrementJob,
          id: consumer.event.data[:id],
          object: consumer.object,
          field_class: consumer.send(:field_class),
          field_name: :field_name,
          by: -1
        ).and_return 0
      end
    end

    context 'when removed job exists' do
      before { allow(Resque).to receive(:remove_delayed).and_return 1 }

      it { expect(consumer.cancel_delayed_decrement(:field_name)).to be_truthy }
    end

    context 'when removed job not exists' do
      before { allow(Resque).to receive(:remove_delayed).and_return 0 }

      it { expect(consumer.cancel_delayed_decrement(:field_name)).to be_falsey }
    end
  end
end
