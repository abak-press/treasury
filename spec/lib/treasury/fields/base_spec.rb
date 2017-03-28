# coding: utf-8

module FieldCallback
  extend ActiveSupport::Concern

  included do
    set_callback :data_changed, :after, :data_changed_callback
  end

  def data_changed_callback; end
end

class TreasuryFieldsBase < Treasury::Fields::Base
  include FieldCallback
end

describe TreasuryFieldsBase do
  subject { described_class.new(nil) }

  context '#data_changed' do
    let(:chaged_objects) { [1, 2, 3] }

    it 'run callbacks' do
      expect(subject).to receive(:run_callbacks).with(:data_changed)
      subject.send(:data_changed, chaged_objects)
    end

    it 'correctly set changed_objects' do
      subject.send(:data_changed, chaged_objects)
      expect(subject.send(:changed_objects)).to eq chaged_objects
    end

    it 'has data_changed callback' do
      expect(subject).to receive(:data_changed_callback)
      subject.send(:data_changed, chaged_objects)
    end
  end
end
