require 'bundler/setup'

require 'treasury'

require 'simplecov'
require 'combustion'
require "factory_girl_rails"
require 'shoulda-matchers'

SimpleCov.start do
  minimum_coverage 73.5
end

Combustion.initialize! :action_mailer, :active_record

require 'rspec/rails'
require 'rspec/given'
require 'apress-rspec'

redis = Treasury.configuration.redis
Redis.current = redis
Resque.redis = redis

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include FactoryGirl::Syntax::Methods

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true

  config.before(:each) { Treasury.configuration.redis.flushall }
  config.after(:each) { Treasury.configuration.redis.flushall }
end
