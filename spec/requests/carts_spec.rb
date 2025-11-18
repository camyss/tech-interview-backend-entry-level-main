require 'rails_helper'

RSpec.describe "/carts", type: :request do
  let!(:product_a) { create(:product, name: 'Produto A', price: 10.0) }
  let!(:product_b) { create(:product, name: 'Produto B', price: 5.0) }
  let(:product_not_found_id) { 9999 }
  
def set_cart_session(cart)
  session[:cart_id] = cart.id 
end
  
  # POST /cart (Registrar produto / Criar carrinho)
  describe "POST /cart" do
    let(:valid_params) { { product_id: product_a.id, quantity: 2 } }

    context 'when no cart exists in session' do
      it 'creates a new Cart and an item' do
        expect {
          post '/cart', params: valid_params, as: :json
        }.to change(Cart, :count).by(1).and(change(CartItem, :count).by(1))
        expect(response).to have_http_status(:ok)
        expect(session[:cart_id]).to eq(Cart.last.id)
      end
    end

    context 'when a cart already exists in session' do
      let!(:existing_cart) { create(:cart) }
      before { set_cart_session(existing_cart) }

      it 'adds a new item to the existing cart' do
        expect {
          post '/cart', params: valid_params, as: :json
        }.to change(existing_cart.cart_items, :count).by(1)
        expect(response).to have_http_status(:ok)
      end
      
      it 'increments quantity if product already exists (o controller tem a lógica de incremento no #create)' do
        # Primeiro POST
        post '/cart', params: { product_id: product_b.id, quantity: 1 }, as: :json
        existing_item = existing_cart.cart_items.find_by(product_id: product_b.id)
        
        # Segundo POST
        expect {
          post '/cart', params: { product_id: product_b.id, quantity: 3 }, as: :json
          existing_item.reload
        }.to change(existing_item, :quantity).by(3)
      end
    end
    
    context 'with invalid parameters (Error Handling - Item Adicional)' do
      it 'returns 404 if product does not exist' do
        post '/cart', params: { product_id: product_not_found_id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Product not found')
      end

      it 'returns 422 if quantity is non-positive' do
        post '/cart', params: { product_id: product_a.id, quantity: 0 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Quantity must be positive')
      end
    end
  end

  # GET /cart (Listar itens)
  describe "GET /cart" do
    context 'when a cart exists in session' do
      let!(:cart) { create(:cart) }
      before { 
        create(:cart_item, cart: cart, product: product_a, quantity: 1, unit_price: 10.0) 
        set_cart_session(cart) 
      }

      it 'returns the cart payload with its products' do
        get '/cart', as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['id']).to eq(cart.id)
        expect(body['products'].count).to eq(1)
        expect(body['products'].first['id']).to eq(product_a.id)
        expect(body['total_price']).to eq(10.0)
      end
    end

    context 'when no cart exists in session' do
      it 'returns an empty cart payload' do
        get '/cart', as: :json
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['id']).to be_nil
        expect(body['products']).to be_empty
        expect(body['total_price']).to eq(0.0)
      end
    end
  end
  
  # PUT /cart/add_item (Alterar quantidade)
  describe "PUT /cart/add_item" do
    let!(:cart) { create(:cart) }
    let!(:item_a) { create(:cart_item, cart: cart, product: product_a, quantity: 2) }
    before { set_cart_session(cart) }

    context 'with valid parameters' do
      it 'updates the quantity of an existing item' do
        put '/cart/add_item', params: { product_id: product_a.id, quantity: 5 }, as: :json
        item_a.reload
        expect(item_a.quantity).to eq(5)
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['total_price']).to eq(50.0) # 5 * 10.0
      end
      
      it 'removes the item if quantity is zero' do
        expect {
          put '/cart/add_item', params: { product_id: product_a.id, quantity: 0 }, as: :json
        }.to change(cart.cart_items, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['total_price']).to eq(0.0)
      end
    end

    context 'with invalid parameters (Error Handling - Item Adicional)' do
      it 'returns 422 if quantity is negative' do
        put '/cart/add_item', params: { product_id: product_a.id, quantity: -1 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Quantity must be positive or zero')
      end

      it 'returns 404 if the item is not in the cart' do
        put '/cart/add_item', params: { product_id: product_b.id, quantity: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Product not found in cart')
      end
    end
  end
  
  # DELETE /cart/:product_id (Remover produto)
  describe "DELETE /cart/:product_id" do
    let!(:cart) { create(:cart) }
    let!(:item_a) { create(:cart_item, cart: cart, product: product_a, quantity: 2) }
    before { set_cart_session(cart) }

    context 'when item is in the cart' do
      it 'removes the item from the cart' do
        expect {
          delete "/cart/#{product_a.id}", as: :json
        }.to change(cart.cart_items, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['products']).to be_empty
        expect(JSON.parse(response.body)['total_price']).to eq(0.0)
      end
    end

    context 'when item is not in the cart' do
      it 'returns 404 Not Found' do
        expect {
          delete "/cart/#{product_b.id}", as: :json
        }.not_to change(cart.cart_items, :count)
        
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Product not found in cart')
      end
    end
    
    it 'returns 404 if cart does not exist' do
      cookies[:_store_session] = nil

      delete "/cart/#{product_a.id}", as: :json 
      expect(response).to have_http_status(:not_found)
    end
  end
end