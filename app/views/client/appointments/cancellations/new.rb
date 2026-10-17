class Views::Client::Appointments::Cancellations::New < Views::Base
  SHOW = Views::Client::Appointments::Show

  CONTENT_CLASS = "flex flex-grow flex-col gap-3.5 px-6 py-6".freeze

  def initialize(tenant:, branding:, appointment:, service:)
    @tenant = tenant
    @branding = branding
    @appointment = appointment
    @service = service
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{SHOW::ACTIVE_TITLE} · #{@tenant.name}", branding: @branding) do
      div(class: SHOW::PAGE_CLASS, data: { appointment: true }) do
        render_band
        render_confirmation
      end
    end
  end

  private

  def render_band
    div(class: SHOW::BAND_CLASS) do
      render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :client, tone: :translucent)
      span(class: SHOW::BAND_NAME_CLASS) { @tenant.name }
    end
  end

  def render_confirmation
    div(class: CONTENT_CLASS) do
      span(class: SHOW::SHEET_TITLE_CLASS) { confirm_prompt }
      span(class: SHOW::SHEET_NOTE_CLASS) { SHOW::CONFIRM_NOTE }
      form_with(url: client_cancellation_path(@appointment.cancel_token), method: :post, class: "contents") do
        button(type: "submit", class: SHOW::CONFIRM_CLASS) { SHOW::CONFIRM_LABEL }
      end
      a(href: client_appointment_path(@appointment.cancel_token), class: SHOW::KEEP_CLASS) { SHOW::KEEP_LABEL }
    end
  end

  def confirm_prompt
    date = @appointment.starts_at.to_date
    Kernel.format(SHOW::CONFIRM_PROMPT, weekday: Views::Client::Bookings::New::WEEKDAY_NAMES[date.wday].downcase, day: date.day,
      month: Views::Client::Bookings::New::MONTH_ABBR[date.month - 1], time: @appointment.starts_at.strftime("%H:%M"))
  end
end
