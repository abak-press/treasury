require 'spec_helper'

RSpec.describe Treasury::Fields::HashOperations do
  let(:hash_field_class) do
    Class.new { include Treasury::Fields::HashOperations }
  end

  it { expect(hash_field_class.singleton_class.included_modules).to include Treasury::HashSerializer }

  describe "#value_as_hash" do
    let(:value_as_hash) { hash_field_class.value_as_hash(object: 123, field: :count) }
    let(:value) { '10:100,20:200' }

    before do
      allow(hash_field_class).to receive(:value).and_return(value)
    end

    it do
      expect(hash_field_class).to receive(:init_accessor).with(object: 123, field: :count)
      expect(value_as_hash).to eq(10 => 100, 20 => 200)
    end
  end
end