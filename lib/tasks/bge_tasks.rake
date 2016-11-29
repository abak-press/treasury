namespace :bge do
  task start: :environment do
    Treasury::BgExecutor.daemonize("start")
  end

  task stop: :environment do
    Treasury::BgExecutor.daemonize("stop")
  end

  task restart: :environment do
    Treasury::BgExecutor.daemonize("restart")
  end
end
