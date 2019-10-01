module Treasury
  module Models
    class EventsLog < ActiveRecord::Base
      self.table_name = 'denormalization.events_log'

      def self.clear(date)
        delete_all(['processed_at::date = ?', date])
      end
    end
  end
end
