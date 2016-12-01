Treasury.configure do |config|
  config.redis = MockRedis.new
  config.job_error_notifications = ['test@test.com']
end
