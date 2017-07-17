# coding: utf-8

describe ::Treasury::Processors::HashOperations do
  let(:dummy_class) do
    Class.new do
      include Treasury::Processors::HashOperations
    end
  end
  let(:dummy) { dummy_class.new }
  let(:raw_value) { '123:321,234:432' }

  describe '#increment_raw_value' do
    let(:result) { dummy.increment_raw_value(raw_value, company_id) }

    context 'when company_id is in raw_value' do
      let(:company_id) { '123' }

      it { expect(result).to eq '123:322,234:432' }
    end

    context 'when company_id is not in raw_value' do
      let(:company_id) { '666' }

      it { expect(result).to eq '123:321,234:432,666:1' }
    end

    context 'when step greater than 1' do
      let(:result) { dummy.increment_raw_value raw_value, company_id, step }

      let(:company_id) { '123' }
      let(:step) { "5" }

      it { expect(result).to eq '123:326,234:432' }
    end
  end

  describe '#decrement_raw_value' do
    let(:result) { dummy.decrement_raw_value(raw_value, company_id) }

    context 'when company_id is in raw_value' do
      let(:company_id) { '123' }

      it { expect(result).to eq '123:320,234:432' }
    end

    context 'when company_id is not in raw_value' do
      let(:company_id) { '666' }

      it { expect(result).to eq '123:321,234:432' }
    end

    context 'when new values goes zero' do
      let(:raw_value) { '123:1,234:432' }
      let(:company_id) { '123' }

      it { expect(result).to eq '234:432' }
    end

    context 'when step greater than 1' do
      let(:result) { dummy.decrement_raw_value raw_value, company_id, step }

      let(:company_id) { '123' }
      let(:step) { "5" }

      it { expect(result).to eq '123:316,234:432' }
    end
  end
end
