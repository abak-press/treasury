module Treasury
  module Pgq
    module Errors
      class PgqError < StandardError
        attr_accessor :inner_exception

        def initialize(inner_exception, message = nil)
          super(message)
          @inner_exception = inner_exception
        end

        def message
          "#{super}\r\n#{@inner_exception.try(:message)}"
        end
      end

      class QueueOrSubscriberNotFoundError < PgqError
        DEFAULT_MESSAGE = "Не найдена очередь или подписчик.".freeze

        def initialize(inner_exception, message = DEFAULT_MESSAGE)
          super(inner_exception, message)
        end
      end
    end
  end
end
