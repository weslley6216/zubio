class Client::BookingsController < Client::BaseController
  WINDOW_DAYS = 14

  def new
    service = Service.active.find(params[:service_id])
    tenant = ActsAsTenant.current_tenant
    professional = tenant.professionals.active.first
    availability = professional && Professional::Availability.new(professional: professional, service: service, dates: window)

    unless availability&.schedule_published?
      return render Views::Client::Bookings::New.new(service: service, tenant: tenant, branding: current_branding, published: false)
    end

    reasons = availability.reasons_by_date
    slots = availability.slots_by_date
    selected = selected_day(reasons)

    render Views::Client::Bookings::New.new(
      service: service,
      tenant: tenant,
      branding: current_branding,
      published: true,
      days: window.to_a,
      reasons: reasons,
      selected_day: selected,
      slots: slots.fetch(selected),
      taken_slots: availability.taken_slots_by_date.fetch(selected),
      reason: reasons.fetch(selected)
    )
  end

  private

  def window
    Date.current..(Date.current + (WINDOW_DAYS - 1))
  end

  def selected_day(reasons)
    requested = parsed_day
    return requested if requested && reasons.key?(requested)

    reasons.find { |_date, reason| reason == :bookable }&.first || window.first
  end

  def parsed_day
    Date.iso8601(params[:day].to_s)
  rescue ArgumentError
    nil
  end
end
