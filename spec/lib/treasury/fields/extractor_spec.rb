RSpec.describe Treasury::Fields::Extractor do
  let(:class_with_extractor) do
    Class.new do
      extend Treasury::Fields::Extractor

      extract_attribute_name :user
    end
  end

  describe '.extract_object' do
    it { expect(class_with_extractor.extract_user(object: {user_id: 1})).to eq 1 }
  end
end
