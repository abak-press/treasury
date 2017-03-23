module Treasury
  module RSpec
    extend ActiveSupport::Concern

    included do
      let(:field) { described_class.instance }
      let(:field_model) { field.field_model }
      let(:worker_model) { field_model.worker }

      before(:suite) do
        Treasury::Models::Field.update_all(active: false)
        Treasury::Models::Worker.update_all(active: false)
      end

      before do
        field_model.update_attribute(:active, true)
        worker_model.update_attribute(:active, true)
      end

      after do
        field_model.processors.each(&:unregister_consumer)

        field_model.update_attribute(:active, false)
        worker_model.update_attribute(:active, false)
      end
    end

    def initialize_field
      field_model.need_initialize!
      field.initialize!
    end

    def process_events
      tick
      Worker.run(worker_model.id)
    end

    def tick
      field_model.processors.map(&:queue).each do |queue|
        queue.work_connection.execute <<-SQL
          SELECT pgq.force_tick('#{queue.pgq_queue_name}');
          SELECT pgq.ticker('#{queue.pgq_queue_name}');
        SQL
      end
    end
  end
end
