namespace :treasury do
  task stop: :environment do
    Treasury::Controller.stop
    Treasury::BgExecutor.daemonize("stop")
  end

  task restart: :environment do
    Treasury::BgExecutor.daemonize("restart")
    ActiveRecord::Base.connection.reconnect!
    Treasury::Controller.restart
  end

  task start: :restart
end
