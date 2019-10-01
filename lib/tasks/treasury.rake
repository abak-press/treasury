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

  namespace :supervisor do
    task stop: "denormalization:supervisor:stop"
  end

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

  namespace :denormalization do
    desc "restart denormalization"
    task restart: :environment do
      Treasury::Controller.restart
    end

    desc "stop supervisor and all workers"
    task stop: :environment do
      Treasury::Controller.stop
    end

    task start: :restart

    desc "stop supervisor"
    namespace :supervisor do
      task stop: :environment do
        Treasury::Controller.stop_supervisor
      end
    end

    desc "Пересоздает триггеры для всех очередей"
    task recreate_triggers: :environment do
      Treasury::Models::Queue.all.each(&:recreate_trigger)
    end

    desc "Удаляет все триггеры системы денормализации"
    task drop_triggers: :environment do
      Apress::Utils::Triggers.drop_triggers(:trigger_pattern => "#{Treasury::Models::Queue::TRIGGER_PREFIX}*")
    end

    desc 'Пересоздает очереди, триггеры и подписки для всех процессоров'
    task recreate_queues: :environment do
      Treasury::Models::Queue.all.each(&:recreate!)
    end
  end
end
