class Cart < ApplicationRecord 

  has_many :cart_items, dependent: :destroy

  def total_price
    cart_items.sum(&:total_price)
  end

  scope :eligible_for_abandonment, -> { 
    where('updated_at < ?', 3.hours.ago).where(abandoned_at: nil)
  }

  scope :abandoned_for_removal, -> { 
    where('abandoned_at < ?', 7.days.ago)
  }
  
  def self.mark_as_abandoned
    eligible_for_abandonment.update_all(abandoned_at: Time.current)
  end

  def self.remove_abandoned
    abandoned_for_removal.destroy_all
  end

end
