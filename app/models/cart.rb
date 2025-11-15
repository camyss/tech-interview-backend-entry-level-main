class Cart < ApplicationRecord

  has_many :cart_items, dependent: :destroy

  def total_price
    # Calcula o preço total somando o total_price de todos os itens
    cart_items.sum(&:total_price)
  end

    # TODO: lógica para marcar o carrinho como abandonado e remover se abandonado
end