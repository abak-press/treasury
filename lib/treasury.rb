# coding: utf-8

require 'active_support'

require 'treasury/version'
require 'treasury/engine'
require 'treasury/bg_executor'

module Treasury
  LIST_DELIMITER = ','.freeze

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end
