# coding: utf-8

require 'spec_helper'

RSpec.describe ::Treasury::Processors::Base do
  let(:instance) { described_class.new }

  let(:object) { '2000' }
  let(:data) do
    {
      '1000' => {count1: '50', count2: '100'},
      '2000' => {count1: '550', count2: '600'}
    }
  end
  let(:field) { double first_field: :count1 }

  before do
    instance.instance_variable_set(:@data, data)
    instance.instance_variable_set(:@object, object)

    allow(instance).to receive(:field).and_return(field)

    allow(instance).to receive(:log_event)
  end

  describe '#current_value' do
    it { expect(instance.current_value :count2).to eq '600' }
  end

  describe '#object_value' do
    before do
      allow(instance.field).to receive(:raw_value).with('3000', :count2).and_return('1050')
    end

    it do
      expect(instance.object_value '1000', :count2).to eq '100'
      expect(instance.object_value '1000').to eq '50'
      expect(instance.object_value '2000').to eq '550'
      expect(instance.object_value '3000', :count2).to eq '1050'
    end
  end

  describe '#form_value' do
    it { expect(instance.form_value '10').to eq '10' }
  end

  describe '#result_row' do
    it { expect(instance.result_row '10').to eq '2000' => '10' }
  end
end