class Administration::CustomAttributesController < AdministrationController
  def index
    set = Keyword::CustomAttribute.all
    set = set.fetch_set combo_params if combo_params

    @attribute_set = set.order(:set_name, :database_field)
  end

  def new
    @custom_attribute = Keyword::CustomAttribute.new
    render :edit
  end

  def edit
  end

  def show
    render :edit
  end

  def create
    @custom_attribute = Keyword::CustomAttribute.new custom_keyword_params

    if @custom_attribute.save
      redirect_to custom_attributes_path
    else
      render :edit
    end
  end

  def update
    if @custom_attribute.update custom_keyword_params
      redirect_to custom_attributes_path
    else
      render :edit
    end
  end

  def destroy
    @custom_attribute.destroy
    redirect_to custom_attributes_path
  end

  private

    def find_resource
      @custom_attribute = Keyword::CustomAttribute.find params[:id]
    end

    def combo_params
      return unless params[:combo_set].present?

      table_name = params[:combo_set].split('_').first
      set_name   = params[:combo_set].split('_').last

      { table_name: table_name, set_name: set_name }
    end

    def custom_keyword_params
      params.require(:custom_attribute).permit(
        :database_field,
        :default_value,
        :help_text,
        :label,
        :required,
        :set_name,
        :visibility,
      )
    end
end
