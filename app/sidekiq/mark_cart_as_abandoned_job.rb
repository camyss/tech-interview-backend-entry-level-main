class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(*args)
# MARCAR como abandonado (sem interação há mais de 3 horas)
    Cart.where('updated_at < ?', 3.hours.ago)
        .where(abandoned_at: nil)
        .update_all(abandoned_at: Time.current)

    # REMOVER carrinhos abandonados há mais de 7 dias
    Cart.where('abandoned_at < ?', 7.days.ago).destroy_all  end
end
