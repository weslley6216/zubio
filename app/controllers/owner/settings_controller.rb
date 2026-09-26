class Owner::SettingsController < Owner::BaseController
  self.panel_section = :settings

  def show
    render Views::Owner::Settings::Show.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      service_counts: Service.count_by_state,
      working_hours_summary: working_hours_summary,
      current_section: panel_section
    )
  end

  private

  def working_hours_summary
    professional = current_owner.professional
    return WorkingHour::Summary::NO_HOURS unless professional

    professional.working_hours_summary
  end
end
