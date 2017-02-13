Treasury.configure do |config|
  config.redis = Redis.new(host: :redis)
  config.job_error_notifications = ['test@test.com']
end
