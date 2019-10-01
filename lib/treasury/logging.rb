require 'class_logger'

module Treasury
  module Logging
    extend ActiveSupport::Concern

    included do
      def self.logger_after_init
        logger.blank_row
      end

      include ::ClassLogger
    end
  end
end
