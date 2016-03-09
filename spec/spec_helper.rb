require 'bundler/setup'
require 'pry-debugger'

require 'simplecov'
SimpleCov.start do
  minimum_coverage 95
end

require 'combustion'
Combustion.initialize!

Treasury::SpecHelpers.stub_core_denormalization
