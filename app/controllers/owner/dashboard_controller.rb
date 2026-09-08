class Owner::DashboardController < Owner::BaseController
  def show
    render Views::Owner::Dashboard::Show.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      owner: current_owner
    )
  end
end
