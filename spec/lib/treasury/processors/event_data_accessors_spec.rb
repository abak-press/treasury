require 'spec_helper'

RSpec.describe ::Treasury::Processors::EventDataAccessors do
  let(:processor) { processor_class.new(build_stubbed('denormalization/processor')) }

  before { allow(processor).to receive(:event).and_return(event_data) }

  describe '.event_data_fields' do
    context 'fast_parsing turned off' do
      let(:processor_class) do
        Class.new(::Treasury::Processors::Base) do
          include ::Treasury::Processors::EventDataAccessors

          event_data_fields :value, fast_parsing: false
        end
      end

      context 'value was changed' do
        let(:event_data) do
          double(data: {value: :new}, prev_data: {value: :old})
        end

        it do
          expect(processor.value).to eq :new
          expect(processor.prev_value).to eq :old
          expect(processor.value_changed?).to be_truthy
        end
      end

      context 'value was not changed' do
        let(:event_data) do
          double(data: {value: :old}, prev_data: {value: :old})
        end

        it do
          expect(processor.value).to eq :old
          expect(processor.prev_value).to eq :old
          expect(processor.value_changed?).to be_falsey
        end
      end
    end

    context 'fast_parsing turned on' do
      let(:processor_class) do
        Class.new(::Treasury::Processors::Base) do
          include ::Treasury::Processors::EventDataAccessors

          event_data_fields :value, fast_parsing: true
        end
      end

      context 'value was changed' do
        let(:event_data) do
          double(raw_data: {value: :new}, raw_prev_data: {value: :old})
        end

        it do
          expect(processor.value).to eq :new
          expect(processor.prev_value).to eq :old
          expect(processor.value_changed?).to be_truthy
        end
      end

      context 'value was not changed' do
        let(:event_data) do
          double(raw_data: {value: :old}, raw_prev_data: {value: :old})
        end

        it do
          expect(processor.value).to eq :old
          expect(processor.prev_value).to eq :old
          expect(processor.value_changed?).to be_falsey
        end
      end
    end
  end
end
