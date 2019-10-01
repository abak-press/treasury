class TreasuryFieldsBase < Treasury::Fields::Base
  include Treasury::Fields::Delayed
end

describe Treasury::Fields::Delayed do
  let(:field_model) { build_stubbed 'denormalization/field' }
  let(:field) { TreasuryFieldsBase.new(field_model) }

  context '#cancel_delayed_increments' do
    after { field.send :cancel_delayed_increments }

    let(:args) { ['field_class' => field_class] }
    let(:field_class) { double('field_class') }

    it do
      expect(Resque).to(
        receive(:remove_delayed_selection).
        with(Treasury::DelayedIncrementJob).
        and_yield(args)
      )
      expect(field_class).to receive(:==).with(field_model.field_class)
    end
  end
end
