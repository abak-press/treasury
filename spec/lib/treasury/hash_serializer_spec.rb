require 'spec_helper'

describe ::Treasury::HashSerializer do
  let(:serializer) { serializer_class.new }
  let(:serializer_class) do
    Class.new { extend ::Treasury::HashSerializer }
  end

  describe '#serialize' do
    let(:serialize) { serializer_class.serialize(value) }

    context 'when value is nil' do
      let(:value) { nil }

      it { expect(serialize).to eq nil }
    end

    context 'when value is empty' do
      let(:value) { {} }

      it { expect(serialize).to eq nil }
    end

    context 'when value ok' do
      let(:value) { {123 => 321, 234 => 432} }

      it { expect(serialize).to eq '123:321,234:432' }
    end
  end

  describe '#deserialize' do
    let(:deserialize) { serializer_class.deserialize(value) }

    context 'when value is nil' do
      let(:value) { nil }

      it { expect(deserialize).to eq({}) }
    end

    context 'when value is empty' do
      let(:value) { '' }

      it { expect(deserialize).to eq({}) }
    end

    context 'when value ok' do
      let(:value) { '123:321,234:432,100:-3' }

      it { expect(deserialize).to eq('123' => 321, '234' => 432, '100' => -3) }
    end
  end
end
