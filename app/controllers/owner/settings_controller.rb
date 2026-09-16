class Owner::SettingsController < Owner::BaseController
  self.panel_section = :settings

  def show
    render Views::Owner::Settings::Show.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      service_counts: Service.count_by_state,
      current_section: panel_section
    )
  end
end
