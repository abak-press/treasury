Daemons::Application.class_eval do
  def exception_log
    # stub
  end
end

daemon = Treasury::BgExecutor::Daemon.new

$running = true

def terminate
  puts "Start terminating..."
  $running = false
end

Signal.trap("TERM") { terminate }
Signal.trap("KILL") { terminate } if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.0.0')
Signal.trap("INT") { terminate }

while($running)
  daemon.execute_job
  sleep 5
end

puts 'Exit'
