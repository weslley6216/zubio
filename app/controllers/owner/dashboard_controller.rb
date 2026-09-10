class Owner::DashboardController < Owner::BaseController
  self.panel_section = :dashboard

  def show
    render Views::Owner::Dashboard::Show.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      owner: current_owner,
      current_section: panel_section
    )
  end
end
