module Treasury
  module Processors
    module Errors
      class ProcessorError < StandardError; end
      class UnknownEventTypeError < ProcessorError; end
      class InconsistencyDataError < ProcessorError; end
    end
  end
end
