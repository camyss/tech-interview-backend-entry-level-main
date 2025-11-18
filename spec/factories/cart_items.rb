# spec/factories/cart_items.rb
FactoryBot.define do
  factory :cart_item do
    association :cart

    product_id { 1 }
    quantity { 1 }
    unit_price { 1000.00 }
  end
end