class FixedAssets::CommoditiesController < AdministrationController
  before_action :find_resource, except: [:index, :new, :create]

  # GET /commodities
  def index
    @commodities = current_company.commodities
      .search_like(search_params)
      .order(order_params)
  end

   # GET /commodities/1
  def show
    render :edit
  end

  # GET /commodities/new
  def new
    @commodity = current_company.commodities.build
  end

  # PATCH /commodities/1
  def update
    if @commodity.update_by(commodity_params, current_user)
      redirect_to edit_commodity_path(@commodity), notice: 'Hyödyke päivitettiin onnistuneesti.'
    else
      render :edit
    end
  end

  # GET /commodities/1/edit
  def edit
  end

  # POST /commodities
  def create
    @commodity = current_company.commodities.build(commodity_create_params)

    if @commodity.save_by current_user
      redirect_to edit_commodity_path(@commodity), notice: 'Hyödyke luotiin onnistuneesti.'
    else
      render :new
    end
  end

  # GET /commodities/1/purchase_orders
  def purchase_orders
    linkable_purchase_orders
  end

  # POST /commodities/1/purchase_orders
  def link_purchase_order
    link_resource

    if @linkable_row.save_by current_user
      redirect_to commodity_purchase_orders_path, notice: 'Tiliöintirivi liitettiin onnistuneesti.'
    else
      linkable_purchase_orders
      render :purchase_orders
    end
  end

  # GET /commodities/1/vouchers
  def vouchers
    linkable_vouchers
  end

  # POST /commodities/1/vouchers
  def link_voucher
    link_resource

    if @linkable_row.save_by current_user
      redirect_to commodity_vouchers_path, notice: 'Tiliöintirivi liitettiin onnistuneesti.'
    else
      linkable_vouchers
      render :vouchers
    end
  end

  def activation
    @commodity.status = 'A'

    if @commodity.update_by(activation_params, current_user)
      redirect_to edit_commodity_path(@commodity), notice: 'Hyödyke aktivoitiin onnistuneesti.'
    else
      @commodity.status = ''
      render :edit
    end
  end

  def generate_rows
    @commodity.generate_rows(params[:selected_fiscal_year])
    redirect_to edit_commodity_path(@commodity)
  end

  private

    def linkable_vouchers
      @vouchers = @commodity.linkable_vouchers.includes(:rows)
    end

    def linkable_purchase_orders
      @purchase_orders = @commodity.linkable_invoices.includes(:rows)
    end

    def activation_params
      params.permit(
        :status
      )
    end

    # Allow only these params for update
    def commodity_params
      params.require(:fixed_assets_commodity).permit(
        :name,
        :description,
        :amount,
        :purchased_at,
        :activated_at,
        :planned_depreciation_type,
        :planned_depreciation_amount,
        :btl_depreciation_type,
        :btl_depreciation_amount,
        :cost_centre,
        :target,
        :project
      )
    end

    # Allow only these params for create
    def commodity_create_params
      params.require(:fixed_assets_commodity).permit(
        :name,
        :description
      )
    end

    def searchable_columns
      [
        :name,
        :description
      ]
    end

    def sortable_columns
      searchable_columns
    end

    def find_resource
      @commodity = current_company.commodities.find(params[:commodity_id] || params[:id])
    end

    def link_resource
      @linkable_row = current_company.voucher_rows.find(params[:voucher_row_id])
      @linkable_row.commodity_id = @commodity.id
    end
end
