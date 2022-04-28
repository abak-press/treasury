source 'https://gems.railsc.ru/'
source 'https://rubygems.org'

# Specify your gem's dependencies in treasury.gemspec

gemspec

gem 'pg', '< 1.0.0'

if RUBY_VERSION < '2.5'
  gem 'sprockets', '< 4.0.0', require: false
end

gem 'json', '< 2', require: false
# NameError: uninitialized constant Pry::Command::ExitAll при попытке выполнить require 'pry-byebug'
gem 'pry', '< 0.13.0', require: false
