require 'spec_helper'

RSpec.describe ::Treasury::Processors::Counters do
  let(:processor) { processor_class.new }

  let(:processor_class) do
    Class.new(::Treasury::Processors::Base) do
      include ::Treasury::Processors::DataAccessors
      define_fields :value, fast_parsing: false
    end
  end

  before do
    allow(processor).to(
      receive(:event).
        and_return(
          double(
            data: {value: :new},
            prev_data: {value: :old}
          )
        )
    )
  end

  describe '.data_fields' do
    it do
      expect(processor.value).to eq :new
      expect(processor.prev_value).to eq :old
      expect(processor.value_changed?).to be_truthy
    end
  end

  describe '.data_fields' do
    it { expect(processor.data_fields).to eq [:value] }
  end
end
