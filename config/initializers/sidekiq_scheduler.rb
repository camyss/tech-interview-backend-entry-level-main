require 'sidekiq-scheduler'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://redis:6379/0") }

  config.on(:startup) do
    schedule_file = Rails.root.join('config', 'sidekiq_schedule.yml')
    if File.exist?(schedule_file)
      schedule = YAML.load_file(schedule_file)
      Sidekiq.schedule = schedule
      Sidekiq::Scheduler.enabled = true
      Sidekiq::Scheduler.reload_schedule!
      Rails.logger.info "Sidekiq Scheduler loaded with #{Sidekiq.schedule&.keys&.count || 0} scheduled job(s)"
    else
      Rails.logger.info "Sidekiq Scheduler: no schedule file found at #{schedule_file}"
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://redis:6379/0") }
end

if Rails.env.test?
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
end
