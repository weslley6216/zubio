class Client::BookingsController < Client::BaseController
  WINDOW_DAYS = 14
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
      client_name: params[:name].to_s, client_phone: params[:phone].to_s)

    return render_receipt(service, professional, result.value) if result.success?

    render_schedule(service: service, selected_day: starts_at&.to_date, status: :unprocessable_entity)
  end

  private

  def current_professional = ActsAsTenant.current_tenant.professionals.active.first

  def render_schedule(service:, selected_day: nil, status: :ok)
    tenant = ActsAsTenant.current_tenant
    availability = current_professional && Professional::Availability.new(professional: current_professional, service: service, dates: window)

    unless availability&.schedule_published?
      return render Views::Client::Bookings::New.new(service: service, tenant: tenant, branding: current_branding, published: false), status: status
    end

    reasons = availability.reasons_by_date
    slots = availability.slots_by_date
    chosen = resolve_day(reasons, selected_day)

    render Views::Client::Bookings::New.new(
      service: service, tenant: tenant, branding: current_branding, published: true,
      days: window.to_a, reasons: reasons, selected_day: chosen,
      slots: slots.fetch(chosen), taken_slots: availability.taken_slots_by_date.fetch(chosen), reason: reasons.fetch(chosen)
    ), status: status
  end

  def render_receipt(service, professional, appointment)
    render Views::Client::Bookings::Receipt.new(
      tenant: ActsAsTenant.current_tenant, branding: current_branding, service: service,
      professional: professional, appointment: appointment, client_name: params[:name].to_s
    )
  end

  def window = Date.current..(Date.current + (WINDOW_DAYS - 1))

  def resolve_day(reasons, requested)
    return requested if requested && reasons.key?(requested)

    reasons.find { |_date, reason| reason == :bookable }&.first || window.first
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
