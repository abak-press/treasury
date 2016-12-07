# coding: utf-8
module Treasury
  module Models
    class SupervisorStatus < ActiveRecord::Base
      self.table_name = 'denormalization.supervisor_status'
      self.primary_key = 'id'

      def terminate
        update_attribute(:need_terminate, true)
      end

      def reset_need_terminate
        update_attribute(:need_terminate, false)
      end
    end
  end
end
