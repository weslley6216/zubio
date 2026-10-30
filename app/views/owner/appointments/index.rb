class Views::Owner::Appointments::Index < Views::Base
  include Phlex::Rails::Helpers::TurboStreamFrom

  WEEKDAY_ABBR = Views::Client::Bookings::New::WEEKDAY_ABBR

  TODAY_LABEL = "HOJE".freeze

  def initialize(tenant:, branding:, day:, days:, appointments:, current_section:, subtitle:, out_of_hours: Set.new, selected: nil, selected_visit_number: nil)
    @tenant = tenant
    @branding = branding
    @day = day
    @days = days
    @appointments = appointments
    @out_of_hours = out_of_hours
    @current_section = current_section
    @subtitle = subtitle
    @selected = selected
    @selected_visit_number = selected_visit_number
  end

  def view_template
    render Views::Layouts::Application.new(title: "Agenda · #{@tenant.name}", branding: @branding, flash_in_content: true, page_refresh: :morph) do
      div(data: { controller: "refresh-on-visible" }) { turbo_stream_from @tenant, :agenda }
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section, subtitle: @subtitle)
      render_day_selector_bar
      render Components::FlashBanner.new(container_class: "#{Components::Owner::Panel::CONTENT_WIDE} grid gap-2 pt-4")
      render Components::Owner::AgendaDay.new(tenant: @tenant, branding: @branding, day: @day, appointments: @appointments,
        out_of_hours: @out_of_hours, selected: @selected, selected_visit_number: @selected_visit_number)
    end
  end

  private

  def render_day_selector_bar
    div(class: "border-b border-line bg-surface") do
      div(class: "#{Components::Owner::Panel::CONTENT_WIDE} py-4") do
        div(class: Components::DayPill::SCROLLER, data: {
          day_selector: true, controller: "day-selector",
          day_selector_selected_class: Components::DayPill::SELECTED,
          day_selector_resting_class: Components::DayPill::RESTING,
          day_selector_weekday_resting_class: Components::DayPill::WEEKDAY_RESTING
        }) { @days.each { |date| render_day_pill(date) } }
      end
    end
  end

  def render_day_pill(date)
    selected = date == @day
    a(href: owner_appointments_path(day: date.iso8601),
      class: [ "#{Components::DayPill::WEEK_ITEM} #{Components::DayPill::FRAME}", (selected ? Components::DayPill::SELECTED : Components::DayPill::RESTING) ],
      data: { day: date.iso8601, day_selector_target: (selected ? "selected" : nil),
              turbo_frame: Components::Owner::AgendaDay::FRAME_ID, turbo_action: "advance", action: "day-selector#mark" },
      aria_current: selected ? "date" : nil) do
      span(class: [ Components::DayPill::WEEKDAY, (Components::DayPill::WEEKDAY_RESTING unless selected) ]) { day_label(date) }
      span(class: Components::DayPill::NUMBER) { date.strftime("%d") }
    end
  end

  def day_label(date) = date == Date.current ? TODAY_LABEL : WEEKDAY_ABBR[date.wday]
end
