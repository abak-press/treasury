# coding: utf-8
module Treasury
  module Models
    class Worker < ActiveRecord::Base
      self.table_name = 'denormalization.workers'
      self.primary_key = 'id'

      has_many :fields, class_name: 'Treasury::Models::Field', inverse_of: :worker

      #validates :name, :presence => true, :length => {:maximum => 25}
      #validates_uniqueness_of :name

      scope :active, -> { where(:active => true) }

      def terminate
        update_attribute(:need_terminate, true)
      end

      def reset_terminate
        update_attribute(:need_terminate, false)
      end
    end
  end
end
