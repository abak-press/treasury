# coding: utf-8

module Treasury
  module Session
    extend ActiveSupport::Concern

    module ClassMethods
      def pid
        @@pid ||= Process.pid
      end

      def process_is_alive?(pid)
        pid && process_exists?(pid)
      end

      def process_is_dead?(pid)
        !process_is_alive?(pid)
      end

      def process_exists?(pid)
        Process.getpgid(pid)
        true
      rescue Errno::ESRCH
        false
      end
    end

    module InstanceMethods
      def pid
        self.class.pid
      end

      def process_is_alive?(pid)
        self.class.process_is_alive?(pid)
      end

      def process_is_dead?(pid)
        self.class.process_is_dead?(pid)
      end
    end
  end
end
