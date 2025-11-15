class CartsController < ApplicationController
  # Registrar um produto (POST /cart)
  def create
    cart = find_or_create_cart
    
    if add_or_update_item(cart)
      render json: format_cart_response(cart.reload), status: :ok
    else
      # Fallback caso a validação falhe de forma inesperada
      render json: { error: 'Invalid product parameters or quantity must be positive.' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => e
    # Erro se o produto não for encontrado
    render json: { error: e.message }, status: :not_found
  rescue ArgumentError => e
    # Erro se a quantidade for inválida
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Listar itens do carrinho atual (GET /cart)
  def show
    cart = Cart.find_by(id: session[:cart_id])

    if cart
      render json: format_cart_response(cart), status: :ok
    else
      # Retorna JSON vazio conforme o contrato da API
      render json: { id: nil, products: [], total_price: 0.0 }, status: :ok
    end
  end

  # Alterar a quantidade de produtos no carrinho (PUT /cart/add_item)
  def add_item
    cart = Cart.find_by!(id: session[:cart_id])
    update_item_quantity(cart)

    render json: format_cart_response(cart.reload), status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Remover um produto do carrinho (DELETE /cart/:product_id)
  def remove_item
    cart = Cart.find_by!(id: session[:cart_id])
    remove_cart_item(cart)

    render json: format_cart_response(cart.reload), status: :ok
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  private

  # Permite apenas os parâmetros de entrada esperados
  def product_params
    params.permit(:product_id, :quantity)
  end

  # Encontra ou cria o carrinho e salva o ID na sessão
  def find_or_create_cart
    cart = Cart.find_by(id: session[:cart_id])

    unless cart
      cart = Cart.create!
      session[:cart_id] = cart.id 
    end
    cart
  end

  # Adiciona item ou incrementa a quantidade
  def add_or_update_item(cart)
    quantity = product_params[:quantity].to_i
    product_id = product_params[:product_id]

    # Tratamento de erro: quantidade deve ser positiva
    raise ArgumentError, 'Quantity must be positive' unless quantity > 0
    product = Product.find_by(id: product_id)
    raise ActiveRecord::RecordNotFound, 'Product not found' unless product

    cart_item = cart.cart_items.find_by(product_id: product.id)

    if cart_item
      cart_item.quantity += quantity
      cart_item.save
    else
      cart.cart_items.create(
        product_id: product.id,
        quantity: quantity,
        unit_price: product.price 
      )
    end
  end

  # Altera a quantidade de um item (inclui remoção se quantidade for 0)
  def update_item_quantity(cart)
    product_id = product_params[:product_id]
    new_quantity = product_params[:quantity].to_i

    # Tratamento de erro: quantidade deve ser positiva ou zero (remover)
    raise ArgumentError, 'Quantity must be positive or zero' unless new_quantity >= 0

    cart_item = cart.cart_items.find_by(product_id: product_id)
    raise ActiveRecord::RecordNotFound, 'Product not found in cart' unless cart_item

    if new_quantity == 0
      cart_item.destroy!
    else
      cart_item.update!(quantity: new_quantity)
    end
  end

  # Remove um item do carrinho
  def remove_cart_item(cart)
    product_id = params[:product_id]

    cart_item = cart.cart_items.find_by(product_id: product_id)
    raise ActiveRecord::RecordNotFound, 'Product not found in cart' unless cart_item

    cart_item.destroy!
  end

  # Formata a resposta JSON para o payload da API
  def format_cart_response(cart)
    products = cart.cart_items.map do |item|
      product = Product.find_by(id: item.product_id)
      {
        id: item.product_id,
        name: product&.name || "Produto Desconhecido",
        quantity: item.quantity,
        unit_price: item.unit_price.to_f,
        total_price: item.total_price.to_f
      }
    end

    {
      id: cart.id,
      products: products,
      total_price: cart.total_price.to_f
    }
  end
end