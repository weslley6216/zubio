class Client::BookingsController < Client::BaseController
  RATE_LIMIT_ALERT = "Muitas tentativas. Tente novamente em instantes.".freeze

  rate_limit to: 10, within: 1.minute, only: :create, name: "booking",
    with: -> { redirect_to new_client_service_booking_path(params[:service_id]), alert: RATE_LIMIT_ALERT }

  def new
    service = Service.active.find(params[:service_id])
    render_schedule(service: service, selected_day: parsed_day)
  end

  def create
    service = Service.active.find(params[:service_id])
    professional = current_professional
    starts_at = parsed_starts_at
    result = Appointment.book(professional: professional, service: service, starts_at: starts_at,
      client: current_client, client_name: params[:name].to_s, client_phone: params[:phone].to_s)

    if result.success?
      notify_owner(result.value)
      notify_client(result.value) if current_client
      return render_receipt(service, professional, result.value)
    end
    return render_race(service, professional, starts_at) if result.reason == :taken

    render_schedule(
      service: service,
      selected_day: starts_at&.to_date,
      selected_slot: (starts_at if result.reason == :invalid_client),
      client_name: params[:name], client_phone: params[:phone], client: result.record,
      status: :unprocessable_content
    )
  end

  private

  def current_professional
    @current_professional ||= ActsAsTenant.current_tenant.professionals.active.first
  end

  def notify_owner(appointment)
    OwnerMailer.new_appointment(ActsAsTenant.current_tenant.id, appointment.id).deliver_later
  rescue StandardError => error
    Rails.logger.error("Owner notification failed for appointment #{appointment.id}: #{error.message}")
  end

  def notify_client(appointment)
    ClientMailer.booking_receipt(ActsAsTenant.current_tenant.id, appointment.id).deliver_later
  rescue StandardError => error
    Rails.logger.error("Client receipt failed for appointment #{appointment.id}: #{error.message}")
  end

  def render_race(service, professional, starts_at)
    day = starts_at.to_date
    availability = Professional::Availability.new(professional: professional, service: service, dates: day..day)
    render Views::Client::Bookings::Race.new(
      tenant: ActsAsTenant.current_tenant, branding: current_branding, service: service, professional: professional,
      selected_day: day, slots: availability.slots_by_date.fetch(day), taken_slots: availability.taken_slots_by_date.fetch(day),
      nearest: availability.nearest_free(starts_at), client_name: current_client&.name || params[:name].to_s,
      client_phone: current_client&.phone_display || params[:phone].to_s, lost_time: starts_at
    ), status: :unprocessable_content
  end

  def render_schedule(service:, selected_day: nil, selected_slot: nil, client_name: nil, client_phone: nil, client: nil, status: :ok)
    tenant = ActsAsTenant.current_tenant
    availability = current_professional && Professional::Availability.new(professional: current_professional, service: service, dates: Appointment.booking_window)

    unless availability&.schedule_published?
      return render Views::Client::Bookings::New.new(service: service, tenant: tenant, branding: current_branding, published: false), status: status
    end

    reasons = availability.reasons_by_date
    slots = availability.slots_by_date
    chosen = resolve_day(reasons, selected_day)
    resolved_slot = (selected_slot if selected_slot && selected_slot.to_date == chosen)

    if turbo_frame_request?
      return render Components::Client::Bookings::Grid.new(
        service: service, slots: slots.fetch(chosen), taken_slots: availability.taken_slots_by_date.fetch(chosen),
        reason: reasons.fetch(chosen), selected_slot: resolved_slot
      ), status: status
    end

    render Views::Client::Bookings::New.new(
      service: service, tenant: tenant, branding: current_branding, published: true,
      days: Appointment.booking_window.to_a, reasons: reasons, selected_day: chosen,
      slots: slots.fetch(chosen), taken_slots: availability.taken_slots_by_date.fetch(chosen), reason: reasons.fetch(chosen),
      selected_slot: resolved_slot, client_name: client_name, client_phone: client_phone,
      name_errors: client ? client.errors[:name] : [], phone_errors: client ? client.errors[:phone] : [],
      signed_in: current_client.present?
    ), status: status
  end

  def render_receipt(service, professional, appointment)
    render Views::Client::Bookings::Receipt.new(
      tenant: ActsAsTenant.current_tenant, branding: current_branding, service: service,
      professional: professional, appointment: appointment, signed_in: current_client.present?
    )
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

  def parsed_starts_at
    Time.zone.iso8601(params[:starts_at].to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
