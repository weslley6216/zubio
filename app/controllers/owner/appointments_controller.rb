class Owner::AppointmentsController < Owner::BaseController
  self.panel_section = :agenda
  self.panel_subtitle = "Agenda"

  def index
    render Views::Owner::Appointments::Index.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      day: selected_day,
      appointments: Appointment.for_day(selected_day),
      current_section: panel_section,
      subtitle: panel_subtitle
    )
  end

  private

  def selected_day
    Date.iso8601(params[:day].to_s)
  rescue ArgumentError
    Date.current
  end
end
