source 'https://gems.railsc.ru/'
source 'https://rubygems.org'

# Specify your gem's dependencies in treasury.gemspec

gemspec

gem 'pg', '< 1.0.0'

if RUBY_VERSION < '2.3'
  gem 'nokogiri', '< 1.10.0', require: false
  gem 'pry-byebug', '< 3.7.0', require: false
  gem 'public_suffix', '< 3.1.0', require: false
  gem 'redis', '< 4.1.2', require: false
  gem 'oj', '< 3.8.0', require: false
  gem 'rspec-rails', '< 4', require: false
end

if RUBY_VERSION < '2.4'
  gem 'mock_redis', '< 0.20.0', require: false
  gem 'shoulda-matchers', '< 4.1.0', require: false
  gem 'redis-namespace', '< 1.7.0', require: false
  gem 'simplecov-html', '< 0.11.0', require: false
end

if RUBY_VERSION < '2.5'
  gem 'sprockets', '< 4.0.0', require: false
end

gem 'json', '< 2', require: false
# NameError: uninitialized constant Pry::Command::ExitAll при попытке выполнить require 'pry-byebug'
gem 'pry', '< 0.13.0', require: false
