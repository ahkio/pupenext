require 'test_helper'

class PermissionTest < ActiveSupport::TestCase
  fixtures %w(
    menus
    permissions
    user_profiles
  )

  setup do
    @read = permissions(:joe_customers_read)
    @update = permissions(:bob_customers_update)
  end

  test 'fixtures is valid' do
    refute_empty Permission.all

    Permission.all.each do |permission|
      assert permission.valid?, "Permission #{permission.nimi}: #{permission.errors.full_messages}"
    end
  end

  test "permission has a user" do
    assert_not_nil @read.user
  end

  test "read access" do
    @read.update_attributes! alias_set: ''
    assert_equal 3, Permission.read_access('/customers').count
    assert_equal 0, Permission.read_access('/customers', alias_set: 'prospekti').count
    assert_equal 0, Permission.read_access('/customers', classic: true).count

    @read.update_attributes! alias_set: 'prospekti'
    assert_equal 2, Permission.read_access('/customers').count
    assert_equal 1, Permission.read_access('/customers', alias_set: 'prospekti').count
    assert_equal 0, Permission.read_access('/customers', classic: true).count
  end

  test "update access" do
    @update.update_attributes! alias_set: ''
    assert_equal 2, Permission.update_access('/customers').count
    assert_equal 0, Permission.update_access('/customers', alias_set: 'prospekti').count
    assert_equal 0, Permission.update_access('/customers', classic: true).count

    @update.update_attributes! alias_set: 'prospekti'
    assert_equal 1, Permission.update_access('/customers').count
    assert_equal 1, Permission.update_access('/customers', alias_set: 'prospekti').count
    assert_equal 0, Permission.update_access('/customers', classic: true).count
  end
end
