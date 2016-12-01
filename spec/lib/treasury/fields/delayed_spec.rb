# coding: utf-8

class TreasuryFieldsBase < Treasury::Fields::Base
  include Treasury::Fields::Delayed
end

describe Treasury::Fields::Delayed do
  Given(:field_model) { build_stubbed 'denormalization/field' }
  Given(:field) { TreasuryFieldsBase.new(field_model) }

  context '#cancel_delayed_increments' do
    after { field.send :cancel_delayed_increments }

    Given(:args) { ['field_class' => field_class] }
    Given(:field_class) { double('field_class') }

    Then do
      expect(Resque).to(
        receive(:remove_delayed_selection).
        with(Treasury::DelayedIncrementJob).
        and_yield(args)
      )
    end

    And { expect(field_class).to receive(:==).with(field_model.field_class) }
  end
end
