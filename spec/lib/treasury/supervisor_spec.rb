require 'spec_helper'

describe Treasury::Supervisor do
  let(:supervisor_status) { create :'denormalization/supervisor_status' }
  let(:supervisor) { described_class.new(supervisor_status) }

  describe '#run_initializers' do
    before { allow(supervisor.class).to receive(:process_is_alive?).and_return(false) }

    after { supervisor.send(:run_initializers) }

    context 'when all fields initialized' do
      before { create 'denormalization/field' }

      it { expect(supervisor).to_not receive(:run_initializer) }
    end

    context 'when exist not initialized field' do
      let!(:field) { create 'denormalization/field', state: ::Treasury::Fields::STATE_NEED_INITIALIZE }

      context 'when process not exist' do
        it { expect(supervisor).to receive(:run_initializer).with(field) }
      end

      context 'when initialize process exist' do
        before { allow(supervisor).to receive(:process_is_alive?).with(field.pid).and_return(true) }

        it { expect(supervisor).to receive(:run_initializer).with(field) }
      end
    end

    context 'when some field in initialize' do
      let!(:field) { create 'denormalization/field', state: ::Treasury::Fields::STATE_IN_INITIALIZE }

      context 'when process not exist' do
        it { expect(supervisor).to receive(:run_initializer).with(field) }
      end

      context 'when initialize process exist' do
        before { allow(supervisor).to receive(:process_is_alive?).with(field.pid).and_return(true) }

        it { expect(supervisor).to_not receive(:run_initializer) }
      end
    end
  end
end
