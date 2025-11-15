class CartItem < ApplicationRecord
  belongs_to :cart
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }

  def total_price
    quantity * unit_price
  end
end