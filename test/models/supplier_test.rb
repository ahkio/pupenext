require 'test_helper'

class SupplierTest < ActiveSupport::TestCase
  fixtures %w(
    product/suppliers
    products
    supplier_product_informations
    suppliers
  )

  setup do
    @supplier = suppliers :domestic_supplier
  end

  test 'all fixtures should be valid' do
    assert @supplier.valid?
  end

  test 'relations' do
    product_supplier = product_suppliers :domestic_product_supplier
    assert_equal @supplier.nimi, product_supplier.supplier.nimi

    assert_not_equal 0, @supplier.products.count

    assert_includes @supplier.supplier_product_informations, supplier_product_informations(:two)
    assert_not_includes @supplier.supplier_product_informations, supplier_product_informations(:one)
  end

  test '.tyyppi enum' do
    expected = {
      'normal'                  => '',
      'for_every_product'       => 'L',
      'travelling_expense_user' => 'K',
      'inactive'                => 'P',
    }

    assert_equal expected, Supplier.tyyppis
  end

  test '.active scope' do
    count = Supplier.all.count

    types = {
      active: ['', 'L', 'K'],
      inactive: %w(P),
    }

    types[:active].each do |type|
      Supplier.all.update_all(tyyppi: type)

      assert_equal count, Supplier.active.count
    end

    types[:inactive].each do |type|
      Supplier.all.update_all(tyyppi: type)

      assert_equal 0, Supplier.active.count
    end
  end
end
