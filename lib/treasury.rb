# coding: utf-8

require 'active_support'

require 'treasury/version'
require 'treasury/engine'
require 'treasury/bg_executor'
require 'treasury/configuration'

require 'resque-integration'
require 'string_tools'
require 'pg_tools'

module Treasury
  LIST_DELIMITER = ','.freeze
  ROOT_REDIS_KEY = 'denormalization'.freeze
  ROOT_LOGGER_DIR = 'denormalization'.freeze

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end
