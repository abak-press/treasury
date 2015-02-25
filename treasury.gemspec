# coding: utf-8
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
  spec.homepage      = ''

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_runtime_dependency 'rails', '>= 3.1.12', '< 4.1'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'apress-gems', '>= 0.2'
end
