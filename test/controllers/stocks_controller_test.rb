require 'test_helper'

class StocksControllerTest < ActionController::TestCase
  fixtures %w(
    products
    shelf_locations
    warehouses
  )

  setup do
    @product = products(:hammer)
  end

  test '#stock_available' do
    get :stock_available, product_id: @product.id,
                          warehouse_ids: [warehouses(:veikkola).id, warehouses(:kontula).id],
                          access_token: users(:bob).api_key

    assert_response :success
    assert_equal({ '198948233': '10.0', '250043353': '2.0' }, json_response)
  end
end
