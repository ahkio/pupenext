class SupplierProductInformationsController < ApplicationController
  include ColumnSort

  def index
    session[:supplier] = params[:supplier] if params[:supplier].present?

    if session[:supplier].present? && search_params.present?
      @supplier = Supplier.find(session[:supplier])

      @supplier_product_informations = @supplier
                                       .supplier_product_informations
                                       .search_like(search_params)
    else
      @supplier_product_informations = SupplierProductInformation.none
    end
  end

  def transfer
    supplier_product_information_transfer = SupplierProductInformationTransfer.new(supplier_product_informations_params,
                                                                                   supplier: session[:supplier])

    duplicates = supplier_product_information_transfer.transfer

    unless duplicates.present?
      return redirect_to supplier_product_informations_url, notice: t('.success')
    end

    @supplier_product_informations = duplicates

    flash[:notice] = t('.duplicates_found')
    render :index

  rescue ActionController::ParameterMissing
    redirect_to supplier_product_informations_url(search_params), alert: t('.not_selected')
  end

  private

  def searchable_columns
    %i(
      manufacturer_ean
      manufacturer_part_number
      product_name
      product_id
    )
  end

  def sortable_columns
    searchable_columns
  end

  def supplier_product_informations_params
    permitted = {}

    new_params = params.require(:supplier_product_informations)

    if new_params[:supplier_product_informations]
      new_params[:supplier_product_informations].keys.each do |tunnus|
        permitted[tunnus] = '1'
      end

      new_params.permit(permitted)
    end

    new_params
  end
end
