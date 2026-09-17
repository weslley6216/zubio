class Owner::Onboarding::LogoController < Owner::Onboarding::BaseController
  self.step = "logo"

  def show
    render_logo
  end

  def update
    ActsAsTenant.current_tenant.update_branding!(tenant_attrs: {}, branding_attrs: logo_attrs, remove_logo: false) if logo_submitted?
    advance!
    redirect_to owner_onboarding_services_path
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = REFUSED
    render_logo(status: :unprocessable_entity)
  end

  private

  def logo_submitted? = params.dig(:branding, :logo).present?

  def logo_attrs = params.require(:branding).permit(:logo)

  def render_logo(status: :ok)
    tenant = ActsAsTenant.current_tenant
    render Views::Owner::Onboarding::Step.new(
      branding: current_branding,
      body: Components::Owner::BrandQuestion::Logo.new(tenant: tenant, branding: current_branding),
      step: "logo", submit_url: owner_onboarding_logo_path, submit_label: "Continuar", secondary: "Pular por enquanto"
    ), status: status
  end
end
