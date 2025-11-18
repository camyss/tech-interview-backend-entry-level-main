require "rails_helper"

RSpec.describe CartsController, type: :routing do
  describe 'routes' do
    it 'routes to #show (GET /cart)' do
      expect(get: '/cart').to route_to('carts#show')
    end

    it 'routes to #create (POST /cart)' do
      # Teste para a criação/adição de produto ao carrinho
      expect(post: '/cart').to route_to('carts#create')
    end

    it 'routes to #add_item via PUT (PUT /cart/add_item)' do
      # Teste para alterar a quantidade
      expect(put: '/cart/add_item').to route_to('carts#add_item')
    end
    
    it 'routes to #remove_item via DELETE (DELETE /cart/:product_id)' do
      # Teste para remover um produto
      expect(delete: '/cart/1').to route_to('carts#remove_item', product_id: '1')
    end
  end
end