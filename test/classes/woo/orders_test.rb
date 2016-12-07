require 'test_helper'

class Woo::OrdersTest < ActiveSupport::TestCase
  setup do
    @woocommerce = Woo::Orders.new(
      company_id: companies(:acme).id,
      orders_path: '/tmp',
    )
  end

  test 'should initialize' do
    assert_instance_of Woo::Orders, @woocommerce
  end

  test 'generates edi_order from json response' do
    json_orders = File.read(Rails.root.join('test', 'assets', 'woocommerce', 'orders.json'))

    assert_match /OSTOTILRIV 1/, @woocommerce.build_edi_order(JSON.parse(json_orders).first)
  end
end
