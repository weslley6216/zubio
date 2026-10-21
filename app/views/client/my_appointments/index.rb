class Views::Client::MyAppointments::Index < Views::Base
  TITLE = "Meus agendamentos".freeze
  BACK_LABEL = "Voltar".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-surface-2 leading-[normal] text-ink".freeze
  HEADER_CLASS = "flex items-center gap-3 bg-brand-600 px-5 py-3.5 text-on-brand".freeze
  BACK_CLASS = "grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-white/18".freeze
  BACK_ICON_CLASS = "h-5 w-5".freeze
  NAME_CLASS = "min-w-0 flex-grow truncate text-[15px] font-extrabold tracking-[-0.01em]".freeze
  MAIN_CLASS = "flex min-w-0 flex-grow flex-col gap-4 px-5 py-5".freeze
  HEADING_CLASS = "text-[18px] font-extrabold tracking-[-0.01em]".freeze
  LIST_CLASS = "flex flex-col gap-2.5".freeze
  ITEM_CLASS = "flex flex-col gap-0.5 rounded-xl border border-line bg-surface p-4".freeze
  ITEM_WHEN_CLASS = "text-[14px] font-bold tabular-nums".freeze
  ITEM_SERVICE_CLASS = "text-[13px] text-ink-muted".freeze

  def initialize(tenant:, branding:, appointments:)
    @tenant = tenant
    @branding = branding
    @appointments = appointments
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding) do
      div(class: PAGE_CLASS) do
        render_header
        main(class: MAIN_CLASS) do
          h1(class: HEADING_CLASS) { TITLE }
          div(class: LIST_CLASS) { @appointments.each { |appointment| render_item(appointment) } }
        end
      end
    end
  end

  private

  def render_header
    header(class: HEADER_CLASS) do
      a(href: establishment_path, class: BACK_CLASS, aria_label: BACK_LABEL) { render_back_icon }
      h2(class: NAME_CLASS) { @tenant.name }
    end
  end

  def render_back_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BACK_ICON_CLASS) do |icon|
      icon.path(d: "m15 6-6 6 6 6")
    end
  end

  def render_item(appointment)
    a(href: client_appointment_path(appointment.cancel_token), class: ITEM_CLASS, data: { my_appointment: true }) do
      span(class: ITEM_WHEN_CLASS) { when_label(appointment) }
      span(class: ITEM_SERVICE_CLASS) { appointment.service.name }
    end
  end

  def when_label(appointment)
    date = appointment.starts_at.to_date
    "#{Views::Client::Bookings::New::WEEKDAY_ABBR[date.wday].capitalize}, #{date.day} #{Views::Client::Bookings::New::MONTH_ABBR[date.month - 1]} · #{appointment.starts_at.strftime("%H:%M")}"
  end
end
