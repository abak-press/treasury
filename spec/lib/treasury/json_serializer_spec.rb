require 'spec_helper'

describe ::Treasury::JsonSerializer do
  let(:serializer) { serializer_class.new }
  let(:serializer_class) do
    Class.new { extend ::Treasury::JsonSerializer }
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
      let(:value) { {'hello' => 321, 'world' => {'hello' => 123}} }

      it { expect(serialize).to eq '{"hello":321,"world":{"hello":123}}' }
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
      let(:value) { '{"hello":321,"world":{"hello":123}}' }

      it { expect(deserialize).to eq('hello' => 321, 'world' => {'hello' => 123}) }
    end
  end
end
