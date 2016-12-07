source 'https://gems.railsc.ru/'
source 'https://rubygems.org'

# Specify your gem's dependencies in treasury.gemspec
if RUBY_VERSION < '2'
  gem 'mime-types', '< 3.0'
  gem 'json', '< 2'
  gem 'pry-debugger'
  gem 'pg', '<= 0.18.4'
  gem 'shoulda-matchers', '< 3.0.0'
else
  gem 'pry-byebug'
  gem 'test-unit'
end

gemspec
