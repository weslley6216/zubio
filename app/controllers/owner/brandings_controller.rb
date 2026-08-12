class Owner::BrandingsController < Owner::BaseController
  def edit
    @tenant = ActsAsTenant.current_tenant
    @branding = current_branding

    render Views::Owner::Brandings::Edit.new(tenant: @tenant, branding: @branding)
  end

  def update
    @tenant = ActsAsTenant.current_tenant

    @tenant.update_branding!(tenant_attrs: tenant_params, branding_attrs: branding_params, remove_logo: remove_logo?)
    redirect_to edit_owner_branding_path, notice: "Marca atualizada."
  rescue ActiveRecord::RecordInvalid
    render Views::Owner::Brandings::Edit.new(tenant: @tenant, branding: @tenant.branding), status: :unprocessable_entity
  end

  private

  def remove_logo?
    ActiveModel::Type::Boolean.new.cast(params.dig(:branding, :remove_logo))
  end

  def tenant_params = params.require(:tenant).permit(:name)
  def branding_params = params.require(:branding).permit(:brand_600, :logo)
end
