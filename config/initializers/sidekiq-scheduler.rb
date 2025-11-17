return unless defined?(Sidekiq) && defined?(Sidekiq::Scheduler)

Sidekiq.configure_server do |config|
  config.on(:startup) do
    Sidekiq::Scheduler.enabled = true
    Sidekiq.set_schedule(
      'abandoned_carts_cleanup', 
      {
        'cron' => '0 * * * *', # Roda a cada hora
        'class' => 'MarkCartAsAbandonedJob',
        'queue' => 'default',
        'description' => 'Mark and remove abandoned shopping carts.'
      }
    )
  end
end