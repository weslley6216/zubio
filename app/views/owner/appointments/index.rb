class Views::Owner::Appointments::Index < Views::Base
  WEEKDAY_ABBR = Views::Client::Bookings::New::WEEKDAY_ABBR

  TODAY_LABEL = "HOJE".freeze

  def initialize(tenant:, branding:, day:, days:, appointments:, current_section:, subtitle:, selected: nil, selected_visit_number: nil)
    @tenant = tenant
    @branding = branding
    @day = day
    @days = days
    @appointments = appointments
    @current_section = current_section
    @subtitle = subtitle
    @selected = selected
    @selected_visit_number = selected_visit_number
  end

  def view_template
    render Views::Layouts::Application.new(title: "Agenda · #{@tenant.name}", branding: @branding, flash_in_content: true) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section, subtitle: @subtitle)
      render_day_selector_bar
      render Components::FlashBanner.new(container_class: "#{Components::Owner::Panel::CONTENT_WIDE} grid gap-2 pt-4")
      render Components::Owner::AgendaDay.new(tenant: @tenant, branding: @branding, day: @day, appointments: @appointments,
        selected: @selected, selected_visit_number: @selected_visit_number)
    end
  end

  private

  def render_day_selector_bar
    div(class: "border-b border-line bg-surface", data: { day_selector: true }) do
      div(class: "#{Components::Owner::Panel::CONTENT_WIDE} grid grid-cols-4 gap-2 py-4 lg:grid-cols-7") do
        @days.each_with_index { |date, index| render_day_pill(date, index) }
      end
    end
  end

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
end
