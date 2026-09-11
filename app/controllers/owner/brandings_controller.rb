class Owner::BrandingsController < Owner::BaseController
  REFUSED = "Não foi possível salvar a marca. Confira os campos destacados.".freeze

  self.panel_section = :branding

  def edit
    render Views::Owner::Brandings::Edit.new(tenant: ActsAsTenant.current_tenant, branding: current_branding, current_section: panel_section)
  end

  def update
    tenant = ActsAsTenant.current_tenant

    tenant.update_branding!(tenant_attrs: tenant_params, branding_attrs: branding_params, remove_logo: remove_logo?)
    redirect_to edit_owner_branding_path, notice: "Marca atualizada."
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = REFUSED
    render Views::Owner::Brandings::Edit.new(tenant: tenant, branding: tenant.branding, current_section: panel_section), status: :unprocessable_entity
  end

  private

  def remove_logo?
    ActiveModel::Type::Boolean.new.cast(params.dig(:branding, :remove_logo))
  end

  def tenant_params = params.require(:tenant).permit(:name)
  def branding_params
    submitted = params.require(:branding).permit(
      :logo, :brand_600, :brand_600_custom, :brand_secondary_600, :brand_secondary_600_custom
    )

    submitted.slice(:logo).merge(
      brand_600: Branding.resolve_color(submitted[:brand_600], submitted[:brand_600_custom]),
      brand_secondary_600: Branding.resolve_color(submitted[:brand_secondary_600], submitted[:brand_secondary_600_custom])
    )
  end
end
