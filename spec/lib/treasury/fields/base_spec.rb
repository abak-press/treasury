module FieldCallback
  extend ActiveSupport::Concern

  included do
    set_callback :data_changed, :after, :data_changed_callback
  end

  def data_changed_callback; end
end

class TreasuryFieldsBase < Treasury::Fields::Base
  include FieldCallback

  def self.value_as_integer(params)
    raise_no_implemented(:integer, params)
  end
end

describe TreasuryFieldsBase do
  let(:field) { build_stubbed :'denormalization/field' }
  subject { described_class.new(field) }

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

  describe 'raise_no_implemented' do
    it do
      expect { described_class.value_as_integer({}) }
        .to raise_error(Treasury::Fields::Errors::NoAccessor)
    end
  end

  describe '#reset_field_value' do
    let(:storage) { double(id: :dummy) }

    before do
      allow(subject).to receive(:logger).and_return Rails.logger
      allow(subject).to receive(:storages).and_return([storage])
    end

    it { expect(storage).to receive(:reset_data).with(nil, [:dummy_field]) }

    after { subject.reset_field_value(:dummy_field) }
  end

  describe '#value' do
    let(:silence) { false }

    before do
      described_class._instance = nil

      allow(field).to receive(:reload)
      allow(Treasury::Fields::Base).to receive(:extract_object)
      allow(Treasury::Fields::Base).to receive(:create_by_class).and_return(subject)
      allow_any_instance_of(Treasury::Fields::Base).to receive(:raw_value_from_storage).and_return(value_from_storage)

      described_class.init_accessor(silence: silence)
    end

    context 'when field initialized' do
      let(:value_from_storage) { 5 }

      it { expect(described_class.value).to eq 5 }
    end

    context 'when field uninitialized' do
      let(:field) { build_stubbed :'denormalization/field', :need_initialize }
      let(:value_from_storage) { nil }

      it { expect { described_class.value }.to raise_error Treasury::Fields::Errors::UninitializedFieldError }

      context 'when silence' do
        let(:silence) { true }

        it { expect(described_class.value).to eq nil }
      end
    end
  end
end
