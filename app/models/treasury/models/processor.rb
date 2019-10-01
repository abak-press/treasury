module Treasury
  module Models
    class Processor < ActiveRecord::Base
      self.table_name = 'denormalization.processors'
      self.primary_key = 'id'

      belongs_to :queue, class_name: 'Treasury::Models::Queue', inverse_of: :processors
      belongs_to :field, class_name: 'Treasury::Models::Field', inverse_of: :processors

      before_destroy :unregister_consumer

      serialize :params, Hash

      require 'treasury/pgq'

      def subscribe!
        unregister_consumer
        create_queue_if_needet
        # TODO: check and create or enable trigger if needet!
        ActiveRecord::Base.pgq_register_consumer(queue.pgq_queue_name, consumer_name, queue.work_connection)
      end

      def unregister_consumer
        ActiveRecord::Base.pgq_unregister_consumer(queue.pgq_queue_name, consumer_name, queue.work_connection)
      end

      def create_queue_if_needet
        return if queue.pgq_queue_exists?

        queue.create_pgq_queue
      end
    end
  end
end
