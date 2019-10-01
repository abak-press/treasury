module Treasury
  module Models
    class Field < ActiveRecord::Base
      self.table_name = 'denormalization.fields'
      self.primary_key = 'id'

      has_many :processors,
               -> { order('processors."oid" ASC') },
               class_name: 'Treasury::Models::Processor',
               dependent: :destroy,
               inverse_of: :field

      belongs_to :worker, class_name: 'Treasury::Models::Worker'

      scope :active, -> { where(active: true) }
      scope :ordered, -> { order(arel_table[:oid]) }
      scope :initialized, -> { where(state: Fields::STATE_INITIALIZED) }
      scope :in_initialize, -> { where(state: Fields::STATE_IN_INITIALIZE) }
      scope :for_initialize_or_in_initialize, -> do
        where(state: [Fields::STATE_NEED_INITIALIZE, Fields::STATE_IN_INITIALIZE])
      end
      scope :for_processing, -> { active.initialized.ordered }

      serialize :params, Hash
      serialize :storage, Array

      def need_initialize!
        update_attribute(:state, Fields::STATE_NEED_INITIALIZE)
      end

      def need_initialize?
        state == Fields::STATE_NEED_INITIALIZE
      end

      def suspend
        update_attribute(:active, false)
      end

      def resume
        update_attribute(:active, true)
      end
    end
  end
end
