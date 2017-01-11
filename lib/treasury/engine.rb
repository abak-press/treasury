# coding: utf-8

require 'rails'

module Treasury
  class Engine < ::Rails::Engine
    config.autoload_paths += Dir["#{config.root}/lib"]

    initializer 'treasury', before: :load_init_rb do |app|
      app.config.paths['db/migrate'].concat(config.paths['db/migrate'].expanded)

      ActiveRecord::Base.extend(Treasury::Pgq) if defined?(ActiveRecord)
      require 'treasury/backwards'
    end

    initializer 'treasury-factories', after: 'factory_girl.set_factory_paths' do |_|
      if defined?(FactoryGirl)
        FactoryGirl.definition_file_paths.unshift root.join('spec', 'factories')
      end
    end
  end
end
