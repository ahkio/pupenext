class SupplierProductInformationsController < ApplicationController
  include ColumnSort

  def index
    session[:supplier] = params[:supplier] if params[:supplier].present?

    unless session[:supplier].present? && search_params.present?
      return @supplier_product_informations = SupplierProductInformation.none
    end

    @supplier = Supplier.find(session[:supplier])

    @supplier_product_informations = @supplier
                                       .supplier_product_informations
                                       .search_like(search_params)
  end

  def transfer
    duplicates = SupplierProductInformationTransfer.transfer(supplier_product_informations_params,
                                                                supplier: session[:supplier])

    unless duplicates.present?
      return redirect_to supplier_product_informations_url, notice: t('.success')
    end

    @supplier_product_informations = duplicates

    flash.now[:notice] = t('.duplicates_found')
    render :index

  rescue ActionController::ParameterMissing
    redirect_to supplier_product_informations_url(search_params), alert: t('.not_selected')
  end

  private

    def searchable_columns
      %i(
        category_text1
        category_text2
        category_text3
        category_text4
        description
        manufacturer_ean
        manufacturer_name
        manufacturer_part_number
        product_name
        product_id
        supplier_part_number
      )
    end

    def sortable_columns
      searchable_columns
    end

    def supplier_product_informations_params
      permitted = {}

      params.require(:supplier_product_informations).permit

      params[:supplier_product_informations].keys.each do |tunnus|
        permitted[tunnus] = %i(
          category_text1
          category_text2
          category_text3
          category_text4
          description
          manufacturer_ean
          manufacturer_part_number
          nakyvyys
          osasto
          p_tree_id
          status
          supplier_part_number
          toimittajan_ostohinta
          toimittajan_saldo
          transfer
          try
          tuotemerkki
        )
      end

      params.require(:supplier_product_informations).permit(permitted)
    end
end
