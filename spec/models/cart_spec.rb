require 'rails_helper'

RSpec.describe Cart, type: :model do
  let!(:product_a) { create(:product, price: 10.0) }
  let!(:product_b) { create(:product, price: 5.0) }
  
  context 'when validating' do
    # verificando a validação de total_price >= 0 (se existir)
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe '#total_price' do
    it 'calculates the total price of all cart items' do
      cart = create(:cart)
      # Item A: 1 x 10.0 = 10.0
      create(:cart_item, cart: cart, product: product_a, quantity: 1, unit_price: product_a.price)
      # Item B: 2 x 5.0 = 10.0
      create(:cart_item, cart: cart, product: product_b, quantity: 2, unit_price: product_b.price)
      
      expect(cart.total_price).to eq(20.0)
    end
  end

  describe '.eligible_for_abandonment' do
    # Deve retornar carrinhos inativos há mais de 3 horas e que ainda não foram abandonados
    it 'returns carts updated more than 3 hours ago and not yet abandoned' do
      # Carrinho Elegível: updated_at > 3 horas atrás, abandoned_at é nil
      eligible_cart = create(:cart, updated_at: 3.hours.and(1.minute).ago, abandoned_at: nil)
      
      # Carrinhos que NÃO devem ser incluídos:
      create(:cart, updated_at: 1.hour.ago, abandoned_at: nil) # Ativo
      create(:cart, updated_at: 4.hours.ago, abandoned_at: 1.day.ago) # Já Abandonado
      
      expect(Cart.eligible_for_abandonment).to include(eligible_cart)
      expect(Cart.eligible_for_abandonment.count).to eq(1)
    end
  end

  describe '.abandoned_for_removal' do
    # O escopo deve retornar carrinhos marcados como abandonados há mais de 7 dias
    it 'returns carts marked as abandoned more than 7 days ago' do
      # Carrinho Elegível para Remoção: abandoned_at > 7 dias atrás
      removable_cart = create(:cart, abandoned_at: 7.days.and(1.minute).ago)
      
      # Carrinho que NÃO deve ser incluído:
      create(:cart, abandoned_at: 6.days.ago) # Abandonado recentemente
      
      expect(Cart.abandoned_for_removal).to include(removable_cart)
      expect(Cart.abandoned_for_removal.count).to eq(1)
    end
  end

  describe '.mark_as_abandoned' do
    # Deve atualizar o campo abandoned_at para Time.current nos carrinhos elegíveis
    it 'marks eligible carts as abandoned at the current time' do
      cart_to_mark = create(:cart, updated_at: 4.hours.ago, abandoned_at: nil)
      Timecop.freeze do 
        Cart.mark_as_abandoned
        cart_to_mark.reload
        expect(cart_to_mark.abandoned_at).to be_within(1.second).of(Time.current)
      end
    end
  end

  describe '.remove_abandoned' do
    # Deve destruir os carrinhos abandonados há mais de 7 dias
    it 'destroys carts abandoned for more than 7 days' do
      create(:cart, abandoned_at: 6.days.ago) 
      cart_to_remove = create(:cart, abandoned_at: 8.days.ago) 
      
      expect { Cart.remove_abandoned }.to change(Cart, :count).by(-1)
      expect(Cart.exists?(cart_to_remove.id)).to be_falsey
    end
  end
end