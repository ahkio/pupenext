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
      pick_date_stock_reserved
    elsif @product.company.parameter.stock_management_by_pick_date_and_with_future_reservations?
      pick_date_and_future_reserved
    else
      default_stock_reserved
    end
  end

  def stock_available
    stock - stock_reserved
  end

  private

    def default_stock_reserved
      # sales, manufacture, and stock trasfer rows reserve stock
      stock_reserved  = @product.sales_order_rows.reserved
      stock_reserved += @product.manufacture_rows.reserved
      stock_reserved += @product.stock_transfer_rows.reserved
      stock_reserved
    end

    def pick_date_stock_reserved(stock_date: @stock_date)
      # sales, manufacture, and stock trasfer rows
      # *reserve stock* if they are due to be picked in the past
      stock_reserved  = @product.sales_order_rows.where('tilausrivi.kerayspvm <= ?', stock_date).reserved
      stock_reserved += @product.manufacture_rows.where('tilausrivi.kerayspvm <= ?', stock_date).reserved
      stock_reserved += @product.stock_transfer_rows.where('tilausrivi.kerayspvm <= ?', stock_date).reserved

      # sales, manufacture, and stock trasfer rows
      # *reserve stock* if they are due to be picked in the future, but are already picked
      stock_reserved += @product.sales_order_rows.picked.where('tilausrivi.kerayspvm > ?', stock_date).reserved
      stock_reserved += @product.manufacture_rows.picked.where('tilausrivi.kerayspvm > ?', stock_date).reserved
      stock_reserved += @product.stock_transfer_rows.picked.where('tilausrivi.kerayspvm > ?', stock_date).reserved

      # manufacture composite rows and manufacture recursive composite rows
      # *decrease stock reservation* if they are due to be picked in the past
      stock_reserved -= @product.manufacture_composite_rows.where('tilausrivi.kerayspvm <= ?', stock_date).reserved
      stock_reserved -= @product.manufacture_recursive_composite_rows.where('tilausrivi.kerayspvm <= ?', stock_date).reserved

      # purchase orders due to arrive in the past *decrease stock reservation*
      stock_reserved -= @product.purchase_order_rows.where('tilausrivi.toimaika <= ?', stock_date).reserved

      stock_reserved
    end

    def pick_date_and_future_reserved
      relations = %w{
        manufacture_composite_rows
        manufacture_recursive_composite_rows
        manufacture_rows
        purchase_order_rows
        sales_order_rows
        stock_transfer_rows
      }

      # fetch all distinct pick dates for all product rows
      dates = [@stock_date]
      dates << relations.map do |relation|
        @product.send(relation)
          .where('tilausrivi.kerayspvm > ?', @stock_date)
          .where('tilausrivi.varattu + tilausrivi.jt != 0')
          .select(:kerayspvm)
          .distinct
          .map(&:kerayspvm)
      end

      # fetch stock reserved for each date
      stock_by_date = dates.flatten.compact.map do |date|
        pick_date_stock_reserved(stock_date: date)
      end

      # return maximum stock reservation in the future (worst case)
      stock_by_date.max || 0
    end
end
