require 'spec_helper'

RSpec.describe Treasury::Fields::Extractor do
  let(:class_with_extractor) do
    Class.new do
      extend Treasury::Fields::Extractor

      extract_attribute_name :user
    end
  end

  describe '.extract_object' do
    context 'when object key not present' do
      it { expect { class_with_extractor.extract_object({}) }.to raise_error(KeyError) }
    end

    context 'when object_id not passed' do
      it { expect { class_with_extractor.extract_object(object: {}) }.to raise_error(ArgumentError) }
    end

    context 'when object_id is nil' do
      it { expect { class_with_extractor.extract_object(object: {user_id: nil}) }.to raise_error(ArgumentError) }
    end

    context 'when object is nil' do
      it { expect { class_with_extractor.extract_object(object: nil) }.to raise_error(ArgumentError) }
    end

    context 'when extract another object' do
      it { expect { class_with_extractor.extract_object(object: {another_object: 1}) }.to raise_error(ArgumentError) }
    end

    context 'when call alias method' do
      it { expect(class_with_extractor.extract_user(object: {user_id: 1})).to eq 1 }
    end

    it 'return object id' do
      user = double(:user, id: 1)

      expect(class_with_extractor.extract_object(object: user)).to eq 1
    end

    it 'returns passed object_id' do
      expect(class_with_extractor.extract_object(object: {user_id: 1})).to eq 1
      expect(class_with_extractor.extract_object(object: {user_id: '1'})).to eq 1
      expect(class_with_extractor.extract_object(object: {user: 1})).to eq 1
      expect(class_with_extractor.extract_object(object: {user: '1'})).to eq 1
    end
  end
end
