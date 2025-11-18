FactoryBot.define do
  factory :cart do
    abandoned_at { nil }
  end

  # Factory para criar um carrinho com itens para testes mais complexos
  factory :cart_with_items, parent: :cart do
    transient do
      items_count { 1 }
    end

    after(:create) do |cart, evaluator|
      create_list(:cart_item, evaluator.items_count, cart: cart)
    end
  end
end