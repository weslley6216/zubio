class Views::Owner::Appointments::Index < Views::Base
  WEEKDAY_ABBR = Views::Client::Bookings::New::WEEKDAY_ABBR
  WEEKDAY_NAMES = Views::Client::Bookings::New::WEEKDAY_NAMES
  MONTH_NAMES = Views::Client::Bookings::New::MONTH_NAMES

  TODAY_LABEL = "HOJE".freeze
  EMPTY_TITLE = "Nenhum agendamento neste dia.".freeze
  SHARE_LABEL = "Seu link".freeze
  SHARE_HELPER = "Mande esse endereço para suas clientes. É por ele que elas escolhem o horário.".freeze

  def initialize(tenant:, branding:, day:, appointments:, current_section:, subtitle:)
    @tenant = tenant
    @branding = branding
    @day = day
    @appointments = appointments
    @current_section = current_section
    @subtitle = subtitle
  end

  def view_template
    render Views::Layouts::Application.new(title: "Agenda · #{@tenant.name}", branding: @branding, flash_in_content: true) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section, subtitle: @subtitle)
      render_day_selector_bar
      render Components::FlashBanner.new(container_class: "#{Components::Owner::Panel::CONTENT_WIDE} grid gap-2 pt-4")
      main(class: "#{Components::Owner::Panel::CONTENT_WIDE} grid gap-3.5 py-5") do
        render_title_row
        @appointments.any? ? render_list : render_empty_state
        render_install_invite
      end
    end
  end

  private

  def render_day_selector_bar
    div(class: "border-b border-line bg-surface") do
      div(class: "#{Components::Owner::Panel::CONTENT_WIDE} grid grid-cols-4 gap-2 py-4 lg:grid-cols-7") do
        day_window.each_with_index { |date, index| render_day_pill(date, index) }
      end
    end
  end

  def day_window = (Date.current..(Date.current + 6)).to_a

  def render_day_pill(date, index)
    selected = date == @day
    a(href: owner_appointments_path(day: date.iso8601),
      class: [ "flex", Components::DayPill::FRAME, (selected ? Components::DayPill::SELECTED : Components::DayPill::RESTING), ("hidden lg:flex" if index >= 4) ],
      aria_current: selected ? "date" : nil) do
      span(class: [ Components::DayPill::WEEKDAY, (Components::DayPill::WEEKDAY_RESTING unless selected) ]) { day_label(date) }
      span(class: Components::DayPill::NUMBER) { date.strftime("%d") }
    end
  end

  def day_label(date) = date == Date.current ? TODAY_LABEL : WEEKDAY_ABBR[date.wday]

  def render_title_row
    div(class: "flex items-baseline gap-2.5") do
      h1(class: "flex-grow text-[20px] font-extrabold tracking-[-0.02em] text-ink") { day_title }
      span(class: "text-[13px] font-bold tabular-nums text-ink-muted") { count_label }
    end
  end

  def day_title = "#{WEEKDAY_NAMES[@day.wday]}, #{@day.day} de #{MONTH_NAMES[@day.month - 1]}"

  def count_label
    count = @appointments.count { |appointment| !appointment.cancelled? }
    "#{count} #{count == 1 ? 'atendimento' : 'atendimentos'}"
  end

  def render_list
    div(class: "grid gap-2.5") do
      @appointments.each { |appointment| render Components::Owner::AppointmentRow.new(appointment: appointment) }
    end
  end

  def render_empty_state
    div(class: "grid gap-3.5") do
      div(class: "grid justify-items-center gap-2 rounded-xl border border-dashed border-line-strong bg-surface px-4 py-5 text-center") do
        render_calendar_icon
        p(class: "text-sm font-bold text-ink") { EMPTY_TITLE }
      end
      render Components::Owner::ShareLink.new(host: @tenant.canonical_host, name: @tenant.name, label: SHARE_LABEL, helper: SHARE_HELPER)
    end
  end

  def render_calendar_icon
    svg(viewBox: "0 0 28 28", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-7 w-7 text-ink-subtle") do |icon|
      icon.rect(x: "3", y: "5", width: "18", height: "16", rx: "3")
      icon.path(d: "M8 3v4M16 3v4M3 11h18")
    end
  end

  def render_install_invite
    render Components::Owner::InstallInvite.new(name: @tenant.name, icon: @branding.invite_icon, initial: @tenant.initial)
  end
end
