require 'rails_helper'

RSpec.describe CartItem, type: :model do
  # Usando FactoryBot para criar um produto e item
  let(:product) { create(:product, price: 10.50) }
  let(:cart_item) { create(:cart_item, product: product, quantity: 2) }

  context 'validations' do
    it { is_expected.to belong_to(:cart) }
    
    it 'is valid with a positive quantity' do
      expect(build(:cart_item, quantity: 1)).to be_valid
    end

    it 'is invalid with a negative quantity' do
      cart_item = build(:cart_item, quantity: -1)
      expect(cart_item).not_to be_valid
      expect(cart_item.errors[:quantity]).to include("must be greater than or equal to 0")
    end
  end

  describe '#total_price' do
    it 'calculates the total price based on quantity and unit price' do
      # 2 produtos * R$10.50 = R$21.00
      expect(cart_item.total_price).to eq(21.00)
    end
    
    it 'returns 0.0 when quantity is 0' do
      zero_item = create(:cart_item, product: product, quantity: 0)
      expect(zero_item.total_price).to eq(0.0)
    end
  end
end