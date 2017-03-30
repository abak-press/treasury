module Treasury
  module RSpec
    module Field
      extend ActiveSupport::Concern

      included do
        let(:field_model) { Models::Field.find_by_field_class!(described_class) }

        let(:initial_state) do
          {
            field_active: true,
            field_need_initialize: true,
            field_processor_exists: true,
            field_need_terminate: false
          }
        end

        it 'initial state is correct' do
          expect(field_model.active?).to eq initial_state.fetch(:field_active)
          expect(field_model.need_initialize?).to eq initial_state.fetch(:field_need_initialize)
          expect(field_model.processors.exists?).to eq initial_state.fetch(:field_processor_exists)
          expect(field_model.need_terminate?).to eq initial_state.fetch(:field_need_terminate)
        end
      end

      def initialize_field
        field_initialize
      end
    end
  end
end