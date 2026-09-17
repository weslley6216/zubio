class Owner::Onboarding::NameController < Owner::Onboarding::BaseController
  self.step = "name"

  def show
    render_name
  end

  def update
    tenant = ActsAsTenant.current_tenant
    tenant.claim_address_from_brand_name!(params.require(:tenant).permit(:name).fetch(:name, ""))
    redirect_to owner_handoff_url(host: tenant.canonical_host, token: current_owner.handoff_token), allow_other_host: true
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = REFUSED
    render_name(status: :unprocessable_entity)
  end

  private

  def render_name(status: :ok)
    tenant = ActsAsTenant.current_tenant
    render Views::Owner::Onboarding::Step.new(
      branding: current_branding,
      body: Components::Owner::BrandQuestion::Name.new(tenant: tenant, branding: current_branding, deriving: true),
      step: "name", submit_url: owner_onboarding_name_path, submit_label: "Continuar"
    ), status: status
  end
end
