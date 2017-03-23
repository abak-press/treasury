module Treasury
  module RSpec
    module Processor
      extend ActiveSupport::Concern

      included do
        let(:worker_model) { field_model.worker }
        let(:field_model) { processor_model.field }
        let(:processor_model) { Models::Processor.find_by_processor_class!(described_class) }
        let(:processor) { processor_model.processor_class.constantize.new(processor_model) }

        let(:initial_state) do
          {worker_active: true, woker_need_terminate: false}
        end

        it 'initial state is correct' do
          expect(worker_model.active?).to eq initial_state.fetch(:worker_active)
          expect(worker_model.need_terminate?).to initial_state.fetch(:woker_need_terminate)
        end
      end

      def initialize_field
        processor_model.subscribe!
        field_initialize
        tick
      end

      def process_events
        tick
        while processor.get_next_batch
          processor.process
        end
      end

      def tick
        processor.send(:work_connection).execute <<-SQL
          SELECT pgq.force_tick('#{processor.queue}');
          SELECT pgq.ticker('#{processor.queue}');
        SQL
      end
    end
  end
end
