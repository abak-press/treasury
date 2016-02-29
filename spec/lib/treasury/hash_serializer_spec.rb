# coding: utf-8
require 'spec_helper'

describe ::Treasury::HashSerializer do
  let(:serializer) { serializer_class.new }
  let(:serializer_class) do
    Class.new { extend ::Treasury::HashSerializer }
  end

  describe '#serialize' do
    let(:serialized) { serializer_class.serialize(value) }

    context 'when value is nil' do
      let(:value) { nil }

      it { expect(serialized).to eq nil }
    end

    context 'when value is empty' do
      let(:value) { {} }

      it { expect(serialized).to eq nil }
    end

    context 'when value ok' do
      let(:value) { {123 => 321, 234 => 432} }

      it { expect(serialized).to eq '123:321,234:432' }
    end
  end

  describe '#deserialize' do
    let(:deserialized) { serializer_class.deserialize(value) }

    context 'when value is nil' do
      let(:value) { nil }

      it { expect(deserialized).to eq({}) }
    end

    context 'when value is empty' do
      let(:value) { '' }

      it { expect(deserialized).to eq({}) }
    end

    context 'when value ok' do
      let(:value) { '123:321,234:432' }

      it { expect(deserialized).to eq(123 => 321, 234 => 432) }
    end
  end
end
