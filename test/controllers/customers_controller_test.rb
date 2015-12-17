require 'test_helper'

class CustomersControllerTest < ActionController::TestCase
  fixtures %w(
    customers
    keyword/customer_categories
    keyword/customer_subcategories
    keywords
  )

  setup do
    @user = users(:bob)
    @customer = customers(:stubborn_customer)
    login @user
  end

  test 'api authorize' do
    get :find_by_email, email: "email@ding.com", access_token: "wrong"
    assert_response :unauthorized

    get :find_by_email, email: "email@ding.com", access_token: @user.api_key
    assert_response :success
  end

  test 'should create a new customer' do
    params = { customer: {
        ytunnus:        '111',
        asiakasnro:     '111',
        nimi:           'Teppo Testaaja',
        nimitark:       '040 5555 555',
        osoite:         'Katukuja 12',
        postino:        '53500',
        postitp:        'Lappeenranta',
        maa:            'fi',
        email:          'teppo@example.com',
        puhelin:        '040 5555 555',
        kieli:          'fi',
        osasto:         '1',
        ryhma:          '10'
      },
      access_token: @user.api_key
    }

    assert_difference('Customer.count') do
      post :create, params

      assert_response :created
      assert assigns(:customer)
      assert_equal "111", json_response["asiakasnro"]
    end
  end

  test 'chn' do
    params = {
      customer: {
        asiakasnro: '123',
        chn: '666'
      },
      access_token: @user.api_key
    }

    post :create, params
    assert_response :unprocessable_entity
  end

  test 'should update customer' do
    patch :update, id: @customer, customer: { nimi: "Antti Asiakas" }, access_token: @user.api_key

    assert_equal "Antti Asiakas", @customer.reload.nimi
    assert_equal "100", json_response["asiakasnro"]
  end

  test 'should not update customer' do
    patch :update, id: @customer, customer: { nimi: "" }, access_token: @user.api_key
    assert_response :unprocessable_entity
    assert_not_equal "", json_response["error_messages"]
  end

  test 'should find customer by email' do
    get :find_by_email, email: "notfound@example.com", access_token: @user.api_key
    assert_response :not_found
    assert_equal "Not found", json_response["error_messages"]

    get :find_by_email, email: @customer.email, access_token: @user.api_key
    assert_response :success
    assert_equal @customer.nimi, json_response["nimi"]
  end
end
