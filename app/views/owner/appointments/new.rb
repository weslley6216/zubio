class Views::Owner::Appointments::New < Views::Base
  UNPUBLISHED_MESSAGE = Views::Client::Bookings::New::UNPUBLISHED_MESSAGE
  UNPUBLISHED_CLASS = Views::Client::Bookings::New::UNPUBLISHED_CLASS
  WEEKDAY_NAMES = Views::Client::Bookings::New::WEEKDAY_NAMES
  WEEKDAY_ABBR = Views::Client::Bookings::New::WEEKDAY_ABBR
  DAY_PILL_TODAY_LABEL = Views::Owner::Appointments::Index::TODAY_LABEL

  TITLE = "Novo agendamento".freeze
  BACK_LABEL = "Voltar".freeze
  CLIENT_LABEL = "Cliente".freeze
  SERVICE_LABEL = "Serviço".freeze
  DAY_LABEL = "Dia".freeze
  TIME_LABEL = "Horário".freeze
  TODAY_LABEL = "hoje".freeze
  MARK_LABEL = "Marcar".freeze
  PHONE_PLACEHOLDER = "(11) 90000-0000".freeze
  NAME_PLACEHOLDER = "Como ela se chama".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-surface-2 leading-[normal] text-ink".freeze
  HEADER_CLASS = "flex items-center gap-3 border-b border-line bg-surface px-5 py-3.5".freeze
  BACK_CLASS = "grid h-11 w-11 flex-none place-items-center rounded-[10px] border border-line bg-surface".freeze
  BACK_ICON_CLASS = "h-5 w-5".freeze
  TITLE_CLASS = "flex-grow text-[16px] font-extrabold tracking-[-0.01em] text-ink".freeze
  MAIN_CLASS = "flex min-w-0 flex-grow flex-col gap-[18px] p-5".freeze
  SECTION_CLASS = "flex min-w-0 flex-col gap-2".freeze
  SECTION_LABEL_CLASS = "text-[11px] font-bold uppercase tracking-[0.08em] text-ink-muted".freeze
  PHONE_FIELD_CLASS = "flex min-h-[48px] items-center gap-2.5 rounded-[10px] border-2 border-brand-600 bg-surface px-3.5".freeze
  PHONE_ICON_CLASS = "h-[18px] w-[18px] flex-none text-ink-subtle".freeze
  PHONE_INPUT_CLASS = "min-w-0 flex-grow bg-transparent text-[15px] font-bold tabular-nums text-ink placeholder:text-ink-subtle placeholder:font-normal focus:outline-none".freeze
  NAME_FIELD_CLASS = "min-h-[46px] w-full rounded-lg border border-line-strong bg-surface px-3 text-[15px] text-ink placeholder:text-ink-subtle".freeze
  SERVICE_SELECT_WRAPPER_CLASS = "relative".freeze
  SERVICE_SELECT_CLASS = "min-h-[52px] w-full appearance-none rounded-[10px] border border-line-strong bg-surface px-3.5 pr-10 text-[15px] font-bold text-ink".freeze
  SERVICE_CHEVRON_CLASS = "pointer-events-none absolute right-3.5 top-1/2 h-[18px] w-[18px] -translate-y-1/2 text-ink-subtle".freeze
  SELECTOR_CLASS = Components::DayPill::STRIP
  DAY_BASE_CLASS = "#{Components::DayPill::ITEM} #{Components::DayPill::FRAME}".freeze
  DAY_SELECTED_CLASS = Components::DayPill::SELECTED
  DAY_FREE_CLASS = Components::DayPill::RESTING
  DAY_DISABLED_CLASS = Components::DayPill::DISABLED
  DAY_WEEKDAY_CLASS = Components::DayPill::WEEKDAY
  DAY_WEEKDAY_FREE_CLASS = Components::DayPill::WEEKDAY_RESTING
  DAY_NUMBER_CLASS = Components::DayPill::NUMBER
  BUTTON_BAR_CLASS = "px-5 pb-[calc(24px+env(safe-area-inset-bottom,0px))]".freeze
  BUTTON_CLASS = "min-h-[50px] w-full rounded-xl bg-brand-600 text-[15px] font-extrabold text-on-brand disabled:bg-surface-3 disabled:text-ink-muted".freeze

  def initialize(tenant:, branding:, professional:, services:, service:, published:, days: [], reasons: {}, selected_day: nil, slots: [], taken_slots: [], reason: nil)
    @tenant = tenant
    @branding = branding
    @professional = professional
    @services = services
    @service = service
    @published = published
    @days = days
    @reasons = reasons
    @selected_day = selected_day
    @slots = slots
    @taken_slots = taken_slots
    @reason = reason
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding) do
      div(class: PAGE_CLASS) do
        render_header
        @published ? render_published : render_unpublished_main
      end
    end
  end

  private

  def render_header
    header(class: HEADER_CLASS) do
      a(href: owner_appointments_path, class: BACK_CLASS, aria_label: BACK_LABEL) { render_back_icon }
      h1(class: TITLE_CLASS) { TITLE }
    end
  end

  def render_back_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BACK_ICON_CLASS) do |icon|
      icon.path(d: "m15 6-6 6 6 6")
    end
  end

  def render_published
    form_with(url: owner_appointments_path, method: :post, class: "contents", data: {
      turbo: false, controller: "slot-selector service-selector submit-lock",
      slot_selector_label_value: MARK_LABEL, slot_selector_include_day_value: "true",
      slot_selector_day_value: button_day_label(@selected_day),
      submit_lock_label_value: "Marcando…", action: SUBMIT_LOCK_ACTIONS
    }) do
      main(class: MAIN_CLASS) do
        render_client_section
        render_service_section
        render_day_section
        render_time_section
      end
      input(type: "hidden", name: "starts_at", data: { slot_selector_target: "input" })
      render_submit_bar
    end
  end

  def render_unpublished_main
    main(class: MAIN_CLASS) do
      render_client_section
      render_service_section if @service
      render_unpublished
    end
  end

  def render_client_section
    div(class: SECTION_CLASS, data: { controller: "client-search" }) do
      span(class: SECTION_LABEL_CLASS) { CLIENT_LABEL }
      div(class: PHONE_FIELD_CLASS) do
        render_search_icon
        input(type: "text", name: "phone", placeholder: PHONE_PLACEHOLDER, inputmode: "tel", autocomplete: "off",
          class: PHONE_INPUT_CLASS, data: { client_search_target: "input", action: "input->client-search#search" })
      end
      render Components::Owner::Appointments::ClientSearch.new(matches: [], query: "")
      input(type: "hidden", name: "client_id", data: { client_search_target: "clientId" })
      render_name_field
    end
  end

  def render_search_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: PHONE_ICON_CLASS) do |icon|
      icon.circle(cx: "11", cy: "11", r: "7")
      icon.path(d: "m20 20-4-4")
    end
  end

  def render_name_field
    div(data: { client_search_target: "nameField" }) do
      input(type: "text", name: "name", placeholder: NAME_PLACEHOLDER, class: NAME_FIELD_CLASS)
    end
  end

  def render_service_section
    div(class: SECTION_CLASS) do
      span(class: SECTION_LABEL_CLASS) { SERVICE_LABEL }
      div(class: SERVICE_SELECT_WRAPPER_CLASS) do
        select(name: "service_id", class: SERVICE_SELECT_CLASS, data: { service_selector_target: "select", action: "change->service-selector#reload" }) do
          @services.each { |service| option(value: service.id, selected: service == @service) { service_option_label(service) } }
        end
        render_chevron_icon
      end
    end
  end

  def service_option_label(service)
    "#{service.name} · #{::Service::Duration.minutes_label(service.duration_minutes)}"
  end

  def render_chevron_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: SERVICE_CHEVRON_CLASS) do |icon|
      icon.path(d: "m6 9 6 6 6-6")
    end
  end

  def render_day_section
    div(class: SECTION_CLASS) do
      span(class: SECTION_LABEL_CLASS) { DAY_LABEL }
      render_day_selector
    end
  end

  def render_day_selector
    div(class: SELECTOR_CLASS, data: {
      day_selector: true, controller: "day-selector",
      day_selector_selected_class: DAY_SELECTED_CLASS,
      day_selector_resting_class: DAY_FREE_CLASS,
      day_selector_weekday_resting_class: DAY_WEEKDAY_FREE_CLASS
    }) { @days.each { |date| render_day(date) } }
  end

  def render_day(date)
    @reasons[date] == :bookable ? render_bookable_day(date) : render_disabled_day(date)
  end

  def render_bookable_day(date)
    selected = date == @selected_day
    a(href: new_owner_appointment_path(service_id: @service.id, day: date.iso8601),
      class: [ DAY_BASE_CLASS, selected ? DAY_SELECTED_CLASS : DAY_FREE_CLASS ],
      data: { day: date.iso8601, day_selector_target: selected ? "selected" : nil, turbo: true,
              turbo_frame: Components::Client::Bookings::Grid::FRAME_ID, turbo_action: "advance",
              day_label: button_day_label(date), action: "day-selector#mark slot-selector#resetDay" },
      aria_current: selected ? "date" : nil) do
      span(class: [ DAY_WEEKDAY_CLASS, (DAY_WEEKDAY_FREE_CLASS unless selected) ]) { day_pill_label(date) }
      span(class: DAY_NUMBER_CLASS) { date.strftime("%d") }
    end
  end

  def render_disabled_day(date)
    div(class: [ DAY_BASE_CLASS, DAY_DISABLED_CLASS ], data: { day: date.iso8601 }, aria_disabled: "true") do
      span(class: DAY_WEEKDAY_CLASS) { day_pill_label(date) }
      span(class: DAY_NUMBER_CLASS) { date.strftime("%d") }
    end
  end

  def day_pill_label(date) = date == Date.current ? DAY_PILL_TODAY_LABEL : WEEKDAY_ABBR[date.wday]

  def render_time_section
    div(class: SECTION_CLASS) do
      span(class: SECTION_LABEL_CLASS) { TIME_LABEL }
      render Components::Client::Bookings::Grid.new(service: @service, slots: @slots, taken_slots: @taken_slots, reason: @reason, selected_slot: nil)
    end
  end

  def render_submit_bar
    div(class: BUTTON_BAR_CLASS) do
      button(type: "submit", disabled: true, class: BUTTON_CLASS,
        data: { slot_selector_target: "submit", submit_lock_target: "button" }) { button_day_prefix }
    end
  end

  def button_day_prefix
    "#{MARK_LABEL} #{button_day_label(@selected_day)}"
  end

  def button_day_label(date)
    date == Date.current ? TODAY_LABEL : WEEKDAY_NAMES[date.wday]
  end

  def render_unpublished
    p(class: UNPUBLISHED_CLASS) { UNPUBLISHED_MESSAGE }
  end
end
