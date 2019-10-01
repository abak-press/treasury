module Treasury
  module Pgq
    class Consumer
      attr_accessor :queue, :consumer, :connection

      def initialize(queue, consumer, connection)
        self.queue = queue
        self.consumer = consumer
        self.connection = connection
      end

      def self.quote(text)
        ActiveRecord::Base.connection.quote(text)
      end

      def self.get_consumer_info(connection = ActiveRecord::Base.connection)
        connection.select_all("select c.*, trunc(extract(minutes from lag)*60 + extract(seconds from lag)) seconds_lag from pgq.get_consumer_info() c")
      end

      def self.consumer_exists?(queue_name, consumer, connection = ActiveRecord::Base.connection)
        connection.select_all("select * from pgq.get_consumer_info() WHERE queue_name = #{quote(queue_name)} AND consumer_name = #{quote(consumer)}").present?
      end

      def self.failed_event_retry(queue_name, consumer, event_id, connection = ActiveRecord::Base.connection)
         connection.select_value(
         "select * from pgq.failed_event_retry(#{self.quote queue_name}, #{self.quote consumer},#{event_id.to_i})")
      end

      def self.failed_event_delete(queue_name, consumer, event_id, connection = ActiveRecord::Base.connection)
         connection.select_value(
           "select * from pgq.failed_event_delete(#{self.quote queue_name}, #{self.quote consumer},#{event_id.to_i})")
      end

      def self.failed_event_count(queue_name, consumer, connection = ActiveRecord::Base.connection)
         connection.select_value("select * from pgq.failed_event_count(#{self.quote queue_name}, #{self.quote consumer})")
      end

      def self.failed_event_list(queue_name, consumer, cnt = nil, offset = nil, connection = ActiveRecord::Base.connection)
         off = ''
         off = ",#{cnt.to_i},#{offset.to_i}" if cnt.present?
         connection.select_all("select * from pgq.failed_event_list(#{self.quote queue_name}, #{self.quote consumer} #{off}) order by ev_id desc")
      end

      def get_batch_events
        @batch_id = get_next_batch
        return nil if @batch_id.nil?
        ActiveRecord::Base.pgq_get_batch_events(@batch_id, connection)
      end

      def get_batch_events_by_cursor(batch_id, cursor_name, fetch_size = 1000, extra_where = nil)
        ActiveRecord::Base.get_batch_events_by_cursor(batch_id, cursor_name, fetch_size, extra_where, connection)
      end

      def get_next_batch
        ActiveRecord::Base.pgq_next_batch(queue, consumer, connection)
      rescue ActiveRecord::StatementInvalid => e
        raise unless e.message =~ /Not subscriber to queue/
        raise Errors::QueueOrSubscriberNotFoundError.new(e)
      end

      def finish_batch
        ActiveRecord::Base.pgq_finish_batch(@batch_id, connection)
      end

      def event_failed(event_id, reason)
        ActiveRecord::Base.pgq_event_failed(@batch_id, event_id, reason, connection)
      end

      def event_retry(event_id, retry_seconds)
        ActiveRecord::Base.pgq_event_retry(@batch_id, event_id, retry_seconds, connection)
      end

      def process
        events = get_batch_events
        return if !events
        events.each do |event|
          perform_event(prepare_event(event))
        end

        finish_batch
        true
      end

      alias perform_batch process

      def perform_event(event)
      end

      def prepare_event(event)
        Event.new event
      end

      #def add_event data
      #  self.class.add_event data
      #end
      #
      #def self.add_event data
      #  ActiveRecord::Base.pgq_insert_event(self.const_get('QUEUE_NAME'), self.const_get('TYPE'), data.to_yaml)
      #end

    end
  end
end
