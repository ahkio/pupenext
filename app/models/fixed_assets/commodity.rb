class FixedAssets::Commodity < ActiveRecord::Base
  include Searchable

  # commodity = hyödyke
  # .voucher = tosite, jolle kirjataan SUMU-poistot
  # .voucher.rows = tosittella on SUMU-poisto tiliöintirivejä
  # .commodity_rows = rivejä, jolla kirjataan EVL poistot
  # .procurement_rows = tiliöintirivejä, joilla on valittu hyödykkeelle kuuluvat hankinnat

  belongs_to :company
  has_one :voucher, class_name: 'Head::Voucher'
  has_many :commodity_rows
  has_many :procurement_rows, class_name: 'Head::VoucherRow'

  def get_options_for_type
    [
      ['Valitse',''],
      ['Tasapoisto kuukausittain','T'],
      ['Tasapoisto vuosiprosentti','P'],
      ['Menojäännöspoisto vuosiprosentti','B']
    ]
  end

  def get_options_for_status
    [
      ['Ei aktivoitu', ''],
      ['Aktivoitu', 'A'],
      ['Poistettu', 'P']
    ]
  end

  def activated?
    status == 'A'
  end

  def generate_rows
    raise RuntimeError, 'Commodity not activated' unless activated?

    generate_voucher_rows
    generate_commodity_rows
  end

  def lock_rows
    commodity_rows.update_all(locked: true)
    voucher.rows.update_all(lukko: "X")
  end

  # Calculates monthly payments within fiscal year
  def divide_to_payments(full_amount, full_count)
    # full_amount = hydykkeen hankintahinta
    # full_count = kokonaispoistoaika kuukausissa
    full_amount = full_amount.to_d
    return [] if full_amount.zero? || full_count.zero?

    payment_count = company.get_months_in_current_fiscal_year

    fiscal_maximum = full_amount / full_count * payment_count
    fiscal_maximum = fiscal_maximum.ceil

    payment_amount = full_amount / full_count
    payment_amount = payment_amount.round(2)

    if full_amount > fiscal_maximum
      full_amount = fiscal_maximum
    end

    remainder = full_amount.divmod(payment_amount)

    result = []

    remainder[0].to_i.times do
      result << payment_amount
    end

    unless remainder[1].zero?
      if remainder[0] < payment_count
        result << remainder[1]
      else
        result[-1] += remainder[1]
      end
    end

    result
  end

  def fixed_by_percentage(full_amount, percentage)
    # full_amount = hydykkeen hankintahinta
    # percentage = vuosipoistoprosentti
    yearly_amount = full_amount * percentage / 100
    payments = full_amount / yearly_amount * 12
    payments = payments.to_i
    divide_to_payments(full_amount, payments)
  end

  def degressive_by_percentage(full_amount, fiscal_percentage, depreciated_amount = 0)
    # full_amount = hydykkeen hankintahinta
    # fiscal_percentage = vuosipoistoprosentti
    # depreciated_amount = jo poistettu summa
    one_year = company.get_months_in_current_fiscal_year
    full_amount = full_amount.to_d

    # Sum the value of previous fiscal reductions
    full_amount = full_amount - depreciated_amount

    fiscal_percentage = fiscal_percentage.to_d / 100
    fiscal_year_depreciations = []
    first_depreciation = full_amount * fiscal_percentage / one_year

    fiscal_year_depreciations << first_depreciation.to_i

    fiscalreduction = full_amount * fiscal_percentage
    keep_running = true

    while keep_running do
      injecthis = (full_amount - fiscal_year_depreciations.sum) * fiscal_percentage / one_year

      if fiscal_year_depreciations.count == one_year - 1
        injecthis = fiscalreduction - fiscal_year_depreciations.sum
        keep_running = false
      end
      injecthis = injecthis.to_i

      fiscal_year_depreciations << injecthis unless injecthis.zero?
    end

    fiscal_year_depreciations
  end

  def fixed_by_month(full_amount, total_number_of_payments, depreciated_payments = 0, depreciated_amount = 0)
    # full_amount = hydykkeen hankintahinta
    # total_number_of_payments = poistojen kokonaismäärä kuukausissa
    # depreciated_payments = jo poistettujen erien lukumäärä
    # depreciated_amount = jo poistettu summa
    fiscal_length = company.get_months_in_current_fiscal_year
    remaining_payments = total_number_of_payments - depreciated_payments
    remaining_amount = full_amount - depreciated_amount

    fiscal_maximum = full_amount.to_d / total_number_of_payments * fiscal_length
    fiscal_maximum = fiscal_maximum.ceil

    if remaining_amount > fiscal_maximum
      remaining_amount = fiscal_maximum
    end

    # Calculate fiscal payments
    if remaining_payments >= fiscal_length
      divide_to_payments(remaining_amount, fiscal_length)
    else
      divide_to_payments(remaining_amount, remaining_payments)
    end
  end

  private

    def create_voucher
      tilikausi = company.get_fiscal_year

      voucher_params = {
        nimi: "Poistoerätosite tilikaudelta #{tilikausi.first}-#{tilikausi.last}",
        laatija: created_by,
        muuttaja: modified_by,
        commodity_id: id
      }

      accounting_voucher = company.vouchers.build(voucher_params)
      accounting_voucher.save!

      self.voucher = accounting_voucher
    end

    def generate_voucher_rows
      create_voucher if voucher.nil?

      activation_date = activated_at
      amounts = calculate_depreciations(:SUMU)

      amounts.each_with_index do |amount, i|
        time = activation_date.advance(months: +i)

        row_params = {
          laatija: created_by,
          tapvm: time.end_of_month,
          summa: amount,
          yhtio: company.yhtio,
          selite: :SUMU,
          tilino: procurement_rows.first.tilino
        }

        voucher.rows.create!(row_params)
      end
    end

    def generate_commodity_rows
      activation_date = activated_at
      amounts = calculate_depreciations(:EVL)

      amounts.each_with_index do |amount, i|
        time = activation_date.advance(months: +i)

        row_params = {
          created_by: created_by,
          modified_by: modified_by,
          transacted_at: time.end_of_month,
          amount: amount,
          description: :EVL,
          account: procurement_rows.first.tilino
        }

        commodity_rows.create!(row_params)
      end
    end

    def calculate_depreciations(depreciation_type)
      case depreciation_type.to_sym
      when :SUMU
        calculation_type = planned_depreciation_type
        calculation_amount = planned_depreciation_amount
        depreciated_sum = voucher.rows.sum(:summa)
        depreciation_amount = voucher.rows.count
      when :EVL
        calculation_type = btl_depreciation_type
        calculation_amount = btl_depreciation_amount
        depreciated_sum = commodity_rows.sum(:amount)
        depreciation_amount = commodity_rows.count
      else
        raise ArgumentError, 'Invalid depreciation_type'
      end

      # Calculation rules
      case calculation_type.to_sym
      when :T
        # Tasapoisto kuukausittain
        fixed_by_month(amount, calculation_amount, depreciation_amount, depreciated_sum)
      when :P
        # Tasapoisto vuosiprosentti
        fixed_by_percentage(amount, calculation_amount)
      when :B
        # Menojäännöspoisto vuosiprosentti
        degressive_by_percentage(amount, calculation_amount, depreciated_sum)
      else
        raise ArgumentError, 'Invalid calculation_type'
      end
    end
end
