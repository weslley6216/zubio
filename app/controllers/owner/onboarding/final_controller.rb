class Owner::Onboarding::FinalController < Owner::BaseController
  def show
    tenant = ActsAsTenant.current_tenant
    professional = Professional.find_by(user_id: current_owner.id)
    render Views::Owner::Onboarding::Final.new(
      tenant: tenant, branding: current_branding,
      owner_name: current_owner.name,
      services: Service.ordered.to_a,
      working_hours: professional&.working_hours&.ordered.to_a,
      logo_attached: current_branding.logo.attached?
    )
  end
end
