# config/routes.rb
require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  resources :products

  # Rotas do Carrinho
  resource :cart, only: [:create, :show], controller: 'carts' do
    collection do
      put 'add_item'             # F3: Alterar quantidade
      delete ':product_id', to: 'carts#remove_item', as: :remove_item # F4: Remover produto
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  root "rails/health#show"
end