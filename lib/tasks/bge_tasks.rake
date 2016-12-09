namespace :bge do
  task run: :environment do
    Treasury::BgExecutor.daemonize("run")
  end

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
