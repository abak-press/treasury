require 'treasury/rspec/field'
require 'treasury/rspec/processor'

module Treasury
  module RSpec
    extend ActiveSupport::Concern

    included do
      let(:field_class) { field_model.field_class.constantize }
      let(:field) { Treasury::Fields::Base.create_by_class(field_class, field_model) }
    end

    def field_initialize
      field.send(:reset_storage_data)

      field.send(:main_connection).transaction do
        field.send(:work_connection).transaction do
          field.send(:lock_storages)
          field.send(:before_initialize)
          field.instance_variable_set(:@total_rows, 0)

          case field.class.initialize_method
          when :offset then field.send(:offset_initialize)
          when :interval then field.send(:interval_initialize)
          else raise 'Unknown initialize method'
          end

          current_snapshot = field.send(:work_connection).select_value('SELECT txid_current_snapshot()')
          field_model.update_attribute(:snapshot_id, current_snapshot)

          field.send(:set_state, Fields::STATE_INITIALIZED)
          field.send(:after_initialize)
        end
      end
    end

    def value_as_string(options)
      field_class.value_as_string(options)
    end

    def value_as_integer(options)
      field_class.value_as_integer(options)
    end
  end
end

RSpec.configure do |config|
  config.include Treasury::RSpec, type: :field
  config.include Treasury::RSpec, type: :processor

  config.include Treasury::RSpec::Field, type: :field
  config.include Treasury::RSpec::Processor, type: :processor

  config.before(:each) { Treasury.configuration.redis.flushall }
end
