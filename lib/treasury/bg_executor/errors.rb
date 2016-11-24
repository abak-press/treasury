# coding: utf-8

module Treasury
  module BgExecutor
    class Error < StandardError; end

    class ConnectionError < Error; end
    class QueueError < Error; end
    class JobExecutionError < Error; end
    class JobNotFound < Error; end
    class JobAccessError < Error; end
  end
end
