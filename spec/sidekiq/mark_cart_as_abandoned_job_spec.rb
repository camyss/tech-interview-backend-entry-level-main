require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  describe '#perform' do
    let!(:cart_to_mark) { create(:cart, updated_at: 4.hours.ago, abandoned_at: nil) }
    let!(:cart_to_remove) { create(:cart, updated_at: 9.days.ago, abandoned_at: 8.days.ago) }
    let!(:active_cart) { create(:cart, updated_at: 1.minute.ago, abandoned_at: nil) }
    
    it 'marks eligible carts as abandoned and removes abandoned carts' do
      Timecop.freeze do 
        expect {
          described_class.new.perform # Executa o job em linha
        }.to change(Cart, :count).by(-1) # Apenas o cart_to_remove deve ser destruído
        
        # Verifica se o carrinho elegível foi marcado
        cart_to_mark.reload
        expect(cart_to_mark.abandoned_at).to be_within(1.second).of(Time.current)
        
        # Verifica se o carrinho removível foi destruído
        expect(Cart.exists?(cart_to_remove.id)).to be_falsey
        
        # Verifica se o carrinho ativo permaneceu intacto
        expect(Cart.exists?(active_cart.id)).to be_truthy
      end
    end
  end
end