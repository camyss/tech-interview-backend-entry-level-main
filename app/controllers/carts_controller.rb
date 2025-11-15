class CartsController < ApplicationController
  # Registrar um produto
  def create
    cart = find_or_create_cart

    if add_or_update_item(cart)
      render json: format_cart_response(cart.reload), status: :ok
    else
      render json: { error: 'Invalid product parameters or quantity must be positive.' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # Listar itens do carrinho atual
  def show
    cart = Cart.find_by(id: session[:cart_id])

    if cart
      render json: format_cart_response(cart), status: :ok
    else
      render json: { id: nil, products: [], total_price: 0.0 }, status: :ok
    end
  end

  # Alterar a quantidade de produtos no carrinho (T0D0)
  def add_item
    head :not_implemented
  end

  # Remover um produto do carrinho (TODO)
  def remove_item
    head :not_implemented
  end

  private

  def product_params
    params.permit(:product_id, :quantity)
  end

  # Encontra ou cria o carrinho
  def find_or_create_cart
    cart = Cart.find_by(id: session[:cart_id])

    unless cart
      cart = Cart.create!
      session[:cart_id] = cart.id # Salva o ID do novo carrinho na sessão
    end
    cart
  end

  # Adiciona ou atualiza o item
  def add_or_update_item(cart)
    quantity = product_params[:quantity].to_i
    product_id = product_params[:product_id]

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
        unit_price: product.price # Usa o preço do Product Model
      )
    end
  end

  # Formata a resposta JSON
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