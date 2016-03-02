module Treasury
  module CoreDenormalizationFake
    ROOT_REDIS_KEY = 'denormalization'.freeze

    module Processors
      module Company
        class Base
        end
      end

      module User
        class Base
          def interesting_event?
            true
          end
        end
      end
    end

    module Fields
      module User
        class Base
        end

        class Companies
        end
      end

      module Company
        class Base
        end

        class Translator
        end
      end

      class Base
      end
    end
  end

  # Treasury::SpecHelpers provides method for stub plugin denormalization classes
  # with fake class.
  #
  # Example:
  # spec_helper.rb
  #
  # require 'treasury/spec_helpers'
  #
  # Treasury::SpecHelpers.stub_core_denormalization
  #
  # RSpec.configure do |config|
  #   ...
  # end
  module SpecHelpers
    def stub_core_denormalization
      Object.const_set('CoreDenormalization', CoreDenormalizationFake)
    end

    module_function :stub_core_denormalization
  end
end
