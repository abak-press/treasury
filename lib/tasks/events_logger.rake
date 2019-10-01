namespace :denormalization do
  namespace :events_logger do
    desc 'Перенос накопленных, за сутки, данных из Redis в БД'
    task daily: :environment do
      date = ENV['date'] || (Date.today - 1.day)
      if date.is_a?(String)
        date_arr = date.split('-')
        date = Date.civil(date_arr[0].to_i, date_arr[1].to_i, date_arr[2].to_i)
      end

      trem = ENV['trem'].nil? ? false : ENV['trem'] == 'true'
      rrem = ENV['rrem'].nil? ? true  : ENV['rrem'] == 'true'

      Treasury::Services::EventsLogger.new.process(date, trem, rrem)
    end

    desc 'Удаление накопленных, за сутки, данных из Redis'
    task delete: :environment do
      date = ENV['date'] || (Date.today - 1.day)
      if date.is_a?(String)
        date_arr = date.split('-')
        date = Date.civil(date_arr[0].to_i, date_arr[1].to_i, date_arr[2].to_i)
      end

      Treasury::Services::EventsLogger.new.delete_events(date)
    end

    desc 'Показать список дат, за которые есть данные в Redis'
    task dates: :environment do
      dates = Treasury::Services::EventsLogger.new.dates_list
      if !dates.empty?
        dates.each do |date, count|
          puts "#{date} - #{count} log rows"
        end
      else
        puts 'Empty.'
      end
    end
  end
end
