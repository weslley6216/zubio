class Owner::BrandingsController < Owner::BaseController
  def edit
    @tenant = ActsAsTenant.current_tenant
    @branding = current_branding

    render Views::Owner::Brandings::Edit.new(tenant: @tenant, branding: @branding)
  end

  def update
    @tenant = ActsAsTenant.current_tenant
    @branding = @tenant.branding || @tenant.build_branding
    remove_logo = ActiveModel::Type::Boolean.new.cast(params.dig(:branding, :remove_logo))

    ActiveRecord::Base.transaction do
      @tenant.update!(tenant_params)
      @branding.update!(branding_params)
    end

    @branding.logo.purge_later if remove_logo && branding_params[:logo].blank?
    Branding::PrecomputeIconVariantsJob.perform_later(@tenant.id) if branding_params[:logo].present?
    redirect_to edit_owner_branding_path, notice: "Marca atualizada."
  rescue ActiveRecord::RecordInvalid
    render Views::Owner::Brandings::Edit.new(tenant: @tenant, branding: @branding), status: :unprocessable_entity
  end

  private

  def tenant_params = params.require(:tenant).permit(:name)
  def branding_params = params.require(:branding).permit(:brand_600, :logo)
end
