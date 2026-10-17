class Owner::AppointmentsController < Owner::BaseController
  self.panel_section = :agenda
  self.panel_subtitle = "Agenda"

  def index
    render_agenda(day: selected_day)
  end

  def show
    appointment = Appointment.find(params[:id])
    render_agenda(day: appointment.starts_at.to_date, selected: appointment)
  end

  private

  def render_agenda(day:, selected: nil)
    render Views::Owner::Appointments::Index.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      day: day,
      appointments: Appointment.for_day(day),
      selected: selected,
      current_section: panel_section,
      subtitle: panel_subtitle
    )
  end

  def selected_day
    Date.iso8601(params[:day].to_s)
  rescue ArgumentError
    Date.current
  end
end
