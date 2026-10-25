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

  def new
    service = Service.active.find(params[:service_id]) if params[:service_id]
    service ||= Service.active.ordered.first
    render_schedule(service: service, selected_day: parsed_day)
  end

  def create
    service = Service.active.find(params[:service_id])
    professional = current_owner.professional
    starts_at = parsed_starts_at
    client = Client.find(params[:client_id]) if params[:client_id].present?
    result = Appointment.book(professional: professional, service: service, starts_at: starts_at,
      client: client, client_name: params[:name].to_s, client_phone: params[:phone].to_s)

    return redirect_to owner_appointment_path(result.value) if result.success?
    return render_race(service: service, professional: professional, starts_at: starts_at, client: client) if result.reason == :taken

    render_schedule(service: service, selected_day: starts_at&.to_date, status: :unprocessable_entity)
  end

  private

  def render_race(service:, professional:, starts_at:, client:)
    day = starts_at.to_date
    availability = Professional::Availability.new(professional: professional, service: service, dates: day..day)

    render Views::Owner::Appointments::Race.new(
      tenant: ActsAsTenant.current_tenant, branding: current_branding, service: service, professional: professional,
      selected_day: day, slots: availability.slots_by_date.fetch(day), taken_slots: availability.taken_slots_by_date.fetch(day),
      nearest: availability.nearest_free(starts_at), client_id: client&.id,
      client_name: client&.name || params[:name].to_s, client_phone: client&.phone_display || params[:phone].to_s, lost_time: starts_at
    ), status: :unprocessable_entity
  end

  def parsed_starts_at
    Time.zone.iso8601(params[:starts_at].to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def render_schedule(service:, selected_day: nil, status: :ok)
    tenant = ActsAsTenant.current_tenant
    professional = current_owner.professional
    availability = service && Professional::Availability.new(professional: professional, service: service, dates: Appointment.booking_window)
    services = Service.active.ordered.to_a

    unless service && availability.schedule_published?
      return render Views::Owner::Appointments::New.new(
        tenant: tenant, branding: current_branding, professional: professional, services: services, service: service, published: false
      ), status: status
    end

    reasons = availability.reasons_by_date
    slots = availability.slots_by_date
    chosen = resolve_day(reasons, selected_day)

    if turbo_frame_request?
      return render Components::Client::Bookings::Grid.new(
        service: service, slots: slots.fetch(chosen), taken_slots: availability.taken_slots_by_date.fetch(chosen),
        reason: reasons.fetch(chosen), selected_slot: nil
      ), status: status
    end

    render Views::Owner::Appointments::New.new(
      tenant: tenant, branding: current_branding, professional: professional, services: services, service: service, published: true,
      days: Appointment.booking_window.to_a, reasons: reasons, selected_day: chosen,
      slots: slots.fetch(chosen), taken_slots: availability.taken_slots_by_date.fetch(chosen), reason: reasons.fetch(chosen)
    ), status: status
  end

  def resolve_day(reasons, requested)
    return requested if requested && reasons.key?(requested)

    reasons.find { |_date, reason| reason == :bookable }&.first || Appointment.booking_window.first
  end

  def parsed_day
    Date.iso8601(params[:day].to_s)
  rescue ArgumentError
    nil
  end

  def render_agenda(day:, selected: nil, selected_visit_number: nil)
    case turbo_frame_request_id
    when Components::Owner::AgendaDay::FRAME_ID
      appointments = Appointment.for_day(day)
      render Components::Owner::AgendaDay.new(tenant: ActsAsTenant.current_tenant, branding: current_branding, day: day,
        appointments: appointments, out_of_hours: out_of_hours(day, appointments),
        selected: selected, selected_visit_number: selected_visit_number)
    when Components::Owner::AppointmentDetail::FRAME_ID
      render Components::Owner::AppointmentDetailFrame.new(selected: selected, selected_visit_number: selected_visit_number)
    else
      appointments = Appointment.for_day(day)
      render Views::Owner::Appointments::Index.new(
        tenant: ActsAsTenant.current_tenant,
        branding: current_branding,
        day: day,
        days: Appointment.booking_window.to_a,
        appointments: appointments,
        out_of_hours: out_of_hours(day, appointments),
        selected: selected,
        selected_visit_number: selected_visit_number,
        current_section: panel_section,
        subtitle: panel_subtitle
      )
    end
  end

  def out_of_hours(day, appointments)
    Professional::Availability.new(professional: current_owner.professional, dates: day..day).outside_hours(appointments).to_set
  end

  def selected_day
    Date.iso8601(params[:day].to_s)
  rescue ArgumentError
    Date.current
  end
end
