class Woo::Products < Woo::Base

  # 1. adds products to webstore
  # 2. update stock of products in webstore

  # Create products to woocommerce
  def create
    created_count = 0
    get_products.each do |product|
      if find_by_sku(product.tuoteno).present?
        logger.info "Tuote #{product.tuoteno} on jo verkkokaupassa"
      else
        response = @woocommerce.post("products", product_hash(product)).parsed_response
        if response["id"]
          created_count += 1
          logger.info "Tuote #{product.tuoteno} #{product.nimitys} lisätty verkkokauppaan"
        else
          # log errors
          logger.error response["message"]
        end
      end
    end

    logger.info "Lisättiin #{created_count} tuotetta verkkokauppaan"
  end

  # Update product stock quantity
  def update
    # Find products where stock has changed, or update all?
    get_products.each do |product|
      if find_by_sku(product.tuoteno).present?
        data = { stock_quantity: product.stock_available.to_s }
        product_id = find_by_sku(product.tuoteno)["id"]
        @woocommerce.put("products/#{product_id}", data).parsed_response
      else
        logger.info "Tuotetta #{product.tuoteno} ei ole verkkokaupassa, joten saldoa ei päivitetty"
      end
    end
  end

  def get_products
    # Näkyviin tuotteet A ja P statuksella, mutta vain ne tuotteet joissa Hinnastoon valinnoissa
    # verkkokauppa näkyvyys päällä
    Product.where(status: ['A', 'P']).where(hinnastoon: 'W')
  end

  def product_hash(product)
    {
      name: product.nimitys,
      slug: product.tuoteno,
      sku: product.tuoteno,
      type: 'simple',
      description: product.kuvaus,
      short_description: product.lyhytkuvaus,
      regular_price: product.myyntihinta.to_s,
      manage_stock: true,
      stock_quantity: product.stock_available.to_s,
      status: 'pending'
    }
  end

  def find_by_sku(sku)
    @woocommerce.get("products", {sku: sku}).parsed_response.first
  end
end
