class Stock
  def initialize(product, stock_date: Date.current)
    @product    = product
    @stock_date = stock_date
  end

  def stock
    return 0 if @product.no_inventory_management?

    @product.shelf_locations.sum(:saldo)
  end

  def stock_reserved
    return 0 if @product.no_inventory_management?

    if @product.company.parameter.stock_management_by_pick_date?
      @product.send(:pick_date_stock_reserved, stock_date: @stock_date)
    elsif @product.company.parameter.stock_management_by_pick_date_and_with_future_reservations?
      @product.send(:pick_date_and_future_reserved, stock_date: @stock_date)
    else
      @product.send(:default_stock_reserved)
    end
  end
end
