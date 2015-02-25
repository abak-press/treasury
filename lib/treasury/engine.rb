# coding: utf-8

require 'rails'

module Treasury
  class Engine < ::Rails::Engine
    config.autoload_paths += Dir["#{config.root}/lib"]
  end
end
