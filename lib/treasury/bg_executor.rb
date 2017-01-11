require "daemons"
require "treasury/bg_executor/errors"

module Treasury
  module BgExecutor
    class << self
      def daemonize(*args)
        options = Treasury.configuration.bge_daemon_options
        options[:ARGV] = args

        file_path = File.expand_path(File.join(File.dirname(__FILE__), "bg_executor", "bg_executor_daemon.rb"))
        Daemons.run(file_path, options)
      end
    end
  end
end
