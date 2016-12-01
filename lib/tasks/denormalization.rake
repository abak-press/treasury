# coding: utf-8
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
end
