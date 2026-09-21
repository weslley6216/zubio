class Owner::Onboarding::FinalController < Owner::BaseController
  def show
    tenant = ActsAsTenant.current_tenant
    render Views::Owner::Onboarding::Final.new(
      tenant: tenant, branding: current_branding,
      services_count: Service.count,
      working_hours: Professional.find_by(user_id: current_owner.id)&.working_hours&.ordered.to_a
    )
  end
end
