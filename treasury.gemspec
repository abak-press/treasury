lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'treasury/version'

Gem::Specification.new do |spec|
  spec.name          = 'treasury'
  spec.version       = Treasury::VERSION
  spec.authors       = ['Andrew N. Shalaev']
  spec.email         = ['isqad88@yandex.ru']
  spec.summary       = %q{Treasury - Denormalized data collection system.}
  spec.description   = %q{Denormalized data collection system.}
  spec.homepage      = 'https://github.com/abak-press/treasury'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.metadata['allowed_push_host'] = 'https://gems.railsc.ru'

  spec.add_runtime_dependency 'rails', '>= 4.0.13', '< 5'
  spec.add_runtime_dependency 'daemons', '>= 1.1.9'
  spec.add_runtime_dependency 'class_logger', '>= 1.0.1'
  spec.add_runtime_dependency 'callbacks_rb', '>= 0.0.1'
  spec.add_runtime_dependency 'redis', '>= 3.2.1'
  spec.add_runtime_dependency 'pg', '>= 0.16'
  spec.add_runtime_dependency 'pg_tools', '>= 1.2.0'
  spec.add_runtime_dependency 'string_tools', '>= 0.6.1'
  spec.add_runtime_dependency 'resque-integration', '>= 1.9'
  spec.add_runtime_dependency 'apress-sources', '>= 0.3.0'
  spec.add_runtime_dependency 'oj', '>= 2.9.9'

  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'factory_girl_rails', '<= 4.8.0'
  spec.add_development_dependency 'apress-rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'combustion', '>= 0.5.3'
  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'shoulda-matchers'
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'pry-byebug'
end
