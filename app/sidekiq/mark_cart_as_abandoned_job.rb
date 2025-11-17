class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(*args)
    Cart.mark_as_abandoned
    
    Cart.remove_abandoned
  end
end