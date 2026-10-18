class Owner::AppointmentsController < Owner::BaseController
  self.panel_section = :agenda
  self.panel_subtitle = "Agenda"

  def index
    render_agenda(day: selected_day)
  end

  def show
    appointment = Appointment.includes(:client, :service).find(params[:id])
    render_agenda(day: appointment.starts_at.to_date, selected: appointment, selected_visit_number: appointment.visit_number)
  end

  private

  def render_agenda(day:, selected: nil, selected_visit_number: nil)
    case turbo_frame_request_id
    when Components::Owner::AgendaDay::FRAME_ID
      render Components::Owner::AgendaDay.new(tenant: ActsAsTenant.current_tenant, branding: current_branding, day: day,
        appointments: Appointment.for_day(day), selected: selected, selected_visit_number: selected_visit_number)
    when Components::Owner::AppointmentDetail::FRAME_ID
      render Components::Owner::AppointmentDetailFrame.new(selected: selected, selected_visit_number: selected_visit_number)
    else
      render Views::Owner::Appointments::Index.new(
        tenant: ActsAsTenant.current_tenant,
        branding: current_branding,
        day: day,
        days: Appointment.booking_window.to_a,
        appointments: Appointment.for_day(day),
        selected: selected,
        selected_visit_number: selected_visit_number,
        current_section: panel_section,
        subtitle: panel_subtitle
      )
    end
  end

  def selected_day
    Date.iso8601(params[:day].to_s)
  rescue ArgumentError
    Date.current
  end
end
