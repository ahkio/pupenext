require 'test_helper'

class HuutokauppaMailTest < ActiveSupport::TestCase
  setup do
    @mails = Hash.new { |h, k| h[k] = [] }

    mail_dir = Rails.root.join('test', 'assets', 'huutokauppa_emails')

    Dir.foreach(mail_dir) do |item|
      next if item.in?(%w(. .. invalid_customer_info))

      key  = item.sub(/_\d\z/, '')
      file = File.read(mail_dir.join(item))

      @mails[key.to_sym] << HuutokauppaMail.new(file)
    end

    @emails_without_customer_info = [
      :auction_ended,
      :bidder_picks_up,
      :delivery_offer_request,
      :delivery_ordered,
      :offer_declined
    ]

    @emails_without_delivery_info = [
      :auction_ended,
      :bidder_picks_up,
      :offer_accepted,
      :offer_automatically_accepted,
      :offer_declined,
      :purchase_price_paid
    ]
  end

  test 'files are read correctly' do
    @mails.each do |key, _value|
      refute_empty @mails[key.to_sym]
    end
  end

  test 'initializes correctly with a raw email source' do
    huutokauppa_mail = nil

    assert_nothing_raised do
      huutokauppa_mail = HuutokauppaMail.new(huutokauppa_email(:offer_automatically_accepted_1))
    end

    assert_equal Mail.new(huutokauppa_email(:offer_automatically_accepted_1)), huutokauppa_mail.mail
  end

  test '#type' do
    @mails.each do |type, mails_of_type|
      mails_of_type.each do |mail|
        assert_equal type, mail.type
      end
    end
  end

  test '#customer_name' do
    assert_equal 'Testi Testit Testitestit', @mails[:offer_accepted][0].customer_name
    assert_equal 'Test-testi Testite',       @mails[:offer_automatically_accepted][0].customer_name
    assert_equal 'Test-testi Testite',       @mails[:purchase_price_paid][0].customer_name

    @mails.values_at(@emails_without_customer_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.customer_name
      end
    end
  end

  test '#customer_name returns nil if name is not found' do
    assert_nil HuutokauppaMail.new(huutokauppa_email(:invalid_customer_info)).customer_name
  end

  test '#customer_email' do
    assert_equal 'testit@testi.tes',     @mails[:offer_accepted][0].customer_email
    assert_equal 'te.testite@testi.tes', @mails[:offer_automatically_accepted][0].customer_email
    assert_equal 'te.testite@testi.tes', @mails[:purchase_price_paid][0].customer_email

    @mails.values_at(@emails_without_customer_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.customer_email
      end
    end
  end

  test '#customer_phone' do
    assert_equal '+123 45 6789012', @mails[:offer_accepted][0].customer_phone
    assert_equal '+123 45 6789012', @mails[:offer_automatically_accepted][0].customer_phone
    assert_equal '+123 45 6789012', @mails[:purchase_price_paid][0].customer_phone

    @mails.values_at(@emails_without_customer_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.customer_phone
      end
    end
  end

  test '#customer_address' do
    assert_equal 'testitestit 12', @mails[:offer_accepted][0].customer_address
    assert_equal 'Testitesti 123', @mails[:offer_automatically_accepted][0].customer_address
    assert_equal 'Testitesti 123', @mails[:purchase_price_paid][0].customer_address

    @mails.values_at(@emails_without_customer_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.customer_address
      end
    end
  end

  test '#customer_postcode' do
    assert_equal '12345', @mails[:offer_accepted][0].customer_postcode
    assert_equal '23456', @mails[:offer_automatically_accepted][0].customer_postcode
    assert_equal '12345', @mails[:purchase_price_paid][0].customer_postcode

    @mails.values_at(@emails_without_customer_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.customer_postcode
      end
    end
  end

  test '#customer_city' do
    assert_equal 'Testi',      @mails[:offer_accepted][0].customer_city
    assert_equal 'Testitesti', @mails[:offer_automatically_accepted][0].customer_city
    assert_equal 'Testitesti', @mails[:purchase_price_paid][0].customer_city

    @mails.values_at(@emails_without_customer_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.customer_city
      end
    end
  end

  test '#customer_country' do
    assert_equal 'Suomi', @mails[:offer_accepted][0].customer_country
    assert_equal 'Suomi', @mails[:offer_automatically_accepted][0].customer_country
    assert_equal 'Suomi', @mails[:purchase_price_paid][0].customer_country

    @mails.values_at(@emails_without_customer_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.customer_country
      end
    end
  end

  test '#delivery_name' do
    assert_equal 'Test-testi Testite',         @mails[:delivery_offer_request][0].delivery_name
    assert_equal 'Test-testi testit Testites', @mails[:delivery_ordered][0].delivery_name

    @mails.values_at(@emails_without_delivery_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.delivery_name
      end
    end
  end

  test '#delivery_address' do
    assert_equal 'Testitesti 123', @mails[:delivery_offer_request][0].delivery_address
    assert_equal 'Testitest 1',    @mails[:delivery_ordered][0].delivery_address

    @mails.values_at(@emails_without_delivery_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.delivery_address
      end
    end
  end

  test '#delivery_postcode' do
    assert_equal '12345', @mails[:delivery_offer_request][0].delivery_postcode
    assert_equal '23456', @mails[:delivery_ordered][0].delivery_postcode

    @mails.values_at(@emails_without_delivery_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.delivery_postcode
      end
    end
  end

  test '#delivery_city' do
    assert_equal 'Testitesti',   @mails[:delivery_offer_request][0].delivery_city
    assert_equal 'Testitestite', @mails[:delivery_ordered][0].delivery_city

    @mails.values_at(@emails_without_delivery_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.delivery_city
      end
    end
  end

  test '#delivery_phone' do
    assert_equal '+123 45 6789012', @mails[:delivery_offer_request][0].delivery_phone
    assert_equal '123 4567890',     @mails[:delivery_ordered][0].delivery_phone

    @mails.values_at(@emails_without_delivery_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.delivery_phone
      end
    end
  end

  test '#delivery_email' do
    assert_equal 'te.testite@testi.tes', @mails[:delivery_offer_request][0].delivery_email
    assert_equal 'test-testi.testites@te-testitest.te', @mails[:delivery_ordered][0].delivery_email

    @mails.values_at(@emails_without_delivery_info).each do |mails|
      mails.each do |mail|
        assert_nil mail.delivery_email
      end
    end
  end

  test '#auction_id' do
    assert_equal '279590', @mails[:auction_ended][0].auction_id
    assert_equal '285888', @mails[:bidder_picks_up][0].auction_id
    assert_equal '270265', @mails[:delivery_offer_request][0].auction_id
    assert_equal '274472', @mails[:delivery_ordered][0].auction_id
    assert_equal '277075', @mails[:offer_accepted][0].auction_id
    assert_equal '270265', @mails[:offer_automatically_accepted][0].auction_id
    assert_equal '277687', @mails[:offer_declined][0].auction_id
    assert_equal '270265', @mails[:purchase_price_paid][0].auction_id
  end

  test '#auction_price' do
    assert_equal 806.0, @mails[:auction_ended][0].auction_price
    assert_equal 210.8, @mails[:bidder_picks_up][0].auction_price
    assert_equal 372.0, @mails[:delivery_offer_request][0].auction_price
    assert_equal 111.6, @mails[:delivery_ordered][0].auction_price
    assert_equal 824.6, @mails[:offer_accepted][0].auction_price
    assert_equal 372.0, @mails[:offer_automatically_accepted][0].auction_price
    assert_equal 62.0,  @mails[:offer_declined][0].auction_price
    assert_equal 372.0, @mails[:purchase_price_paid][0].auction_price
  end
end
