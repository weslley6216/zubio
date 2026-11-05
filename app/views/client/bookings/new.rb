class Views::Client::Bookings::New < Views::Base
  BACK_LABEL = "Voltar".freeze
  SERVICE_STEP = "Serviço".freeze
  DAY_STEP = "Dia".freeze
  TIME_STEP = "Horário".freeze
  DAYS_OFF_HINT = "Dias em cinza: sem horário livre.".freeze
  DAY_OFF_HINT = "%<weekday>s está em cinza: sem horário livre.".freeze
  UNPUBLISHED_MESSAGE = "Este estabelecimento ainda não publicou horários.".freeze
  CONFIRM_LABEL = "Confirmar".freeze
  SUMMARY_SEPARATOR = " · ".freeze
  DATA_STEP = "Seus dados".freeze
  NAME_LABEL = "Nome".freeze
  NAME_PLACEHOLDER = "Como você se chama".freeze
  PHONE_LABEL = "Celular".freeze
  PHONE_PLACEHOLDER = "(11) 90000-0000".freeze
  DATA_HINT = "Sem senha, sem cadastro.".freeze
  SLOT_TAKEN_NOTICE = "Esse horário acabou de ser ocupado. Escolha outro.".freeze
  SLOT_TAKEN_NOTICE_CLASS = "text-[12px] font-bold text-(--theme-danger-on-bg)".freeze

  PAGE_CLASS = Views::Client::Frame::PAGE
  HEADER_CLASS = Views::Client::Frame::HEADER
  BACK_CLASS = Views::Client::Frame::BACK
  BACK_ICON_CLASS = Views::Client::Frame::BACK_ICON
  NAME_CLASS = Views::Client::Frame::NAME
  MAIN_CLASS = "flex min-w-0 flex-grow flex-col gap-[22px] px-5 pt-[22px] pb-[120px]".freeze
  STEP_CLASS = "flex min-w-0 flex-col gap-2.5".freeze
  STEP_LABEL_ROW_CLASS = "flex items-center gap-2.5".freeze
  STEP_NUMBER_CLASS = "grid h-6 w-6 place-items-center rounded-full bg-(--theme-bg-tint) text-[12px] font-extrabold".freeze
  STEP_TITLE_CLASS = "text-[15px] font-extrabold tracking-[-0.01em]".freeze
  SERVICE_ROW_CLASS = "flex items-center gap-3 rounded-xl border-2 border-(--theme-accent) bg-(--theme-card) px-4 py-3.5 text-(--theme-on-card)".freeze
  SERVICE_TEXT_CLASS = "flex min-w-0 flex-grow flex-col gap-0.5".freeze
  SERVICE_NAME_CLASS = "text-[14px] font-bold".freeze
  SERVICE_META_CLASS = "text-[12px] tabular-nums text-(--theme-on-card-muted)".freeze
  SERVICE_PRICE_CLASS = "flex-none rounded-full bg-(--theme-accent) px-3 py-[7px] text-[13px] font-extrabold tabular-nums text-(--theme-on-accent)".freeze
  SELECTOR_CLASS = Components::DayPill::STRIP
  DAY_BASE_CLASS = "#{Components::DayPill::ITEM} #{Components::DayPill::FRAME}".freeze
  DAY_SELECTED_CLASS = "bg-(--theme-accent) text-(--theme-on-accent) ring-2 ring-[color:var(--theme-selected-ring,transparent)]".freeze
  DAY_FREE_CLASS = "border border-(--theme-card-line) bg-(--theme-card-chip) text-(--theme-on-card)".freeze
  DAY_DISABLED_CLASS = "border border-dashed border-(--theme-ghost) bg-(--theme-card-chip) text-(--theme-on-bg-muted)".freeze
  DAY_WEEKDAY_CLASS = Components::DayPill::WEEKDAY
  DAY_WEEKDAY_FREE_CLASS = "text-(--theme-on-card-muted)".freeze
  DAY_NUMBER_CLASS = Components::DayPill::NUMBER
  HINT_CLASS = "text-[12px] text-(--theme-on-bg-muted)".freeze
  DATA_HINT_CLASS = "text-[12px] text-(--theme-on-bg-muted)".freeze
  UNPUBLISHED_CLASS = "rounded-xl bg-(--theme-card) p-6 text-[14px] text-(--theme-on-card-muted)".freeze
  CONFIRM_BAR_CLASS = "sticky bottom-0 -mt-[100px] flex items-center gap-3 border-t border-(--theme-card-line) bg-(--theme-card) px-5 pt-3.5 pb-[calc(18px+env(safe-area-inset-bottom,0px))] text-(--theme-on-card)".freeze
  CONFIRM_SUMMARY_CLASS = "flex min-w-0 flex-grow flex-col gap-0.5".freeze
  CONFIRM_BUTTON_CLASS = "min-h-[46px] flex-none rounded-[10px] bg-(--theme-accent) px-5 text-[15px] font-extrabold text-(--theme-on-accent) disabled:bg-(--theme-card-chip) disabled:text-(--theme-on-card-muted)".freeze
  FIELD_WRAPPER_CLASS = "flex flex-col gap-1.5".freeze
  FIELD_LABEL_CLASS = "text-[11px] font-bold uppercase tracking-[0.06em] text-(--theme-on-bg-muted)".freeze
  FIELD_CLASS = "min-h-[46px] w-full rounded-lg border border-(--theme-field-line) bg-(--theme-card-chip) px-3 text-[15px] text-(--theme-on-bg) placeholder:text-(--theme-on-bg-muted)".freeze

  def initialize(service:, tenant:, branding:, published:, days: [], reasons: {}, selected_day: nil, slots: [], taken_slots: [], reason: nil,
    selected_slot: nil, client_name: nil, client_phone: nil, name_errors: [], phone_errors: [], signed_in: false)
    @service = service
    @tenant = tenant
    @branding = branding
    @published = published
    @days = days
    @reasons = reasons
    @selected_day = selected_day
    @slots = slots
    @taken_slots = taken_slots
    @reason = reason
    @selected_slot = selected_slot
    @client_name = client_name
    @client_phone = client_phone
    @name_errors = name_errors
    @phone_errors = phone_errors
    @signed_in = signed_in
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding) do
      div(class: PAGE_CLASS, data: { page: true }) do
        render_header
        @published ? render_published : render_unpublished_main
      end
    end
  end

  private

  def render_header
    header(class: HEADER_CLASS) do
      a(href: establishment_path, class: BACK_CLASS, aria_label: BACK_LABEL) { render_back_icon }
      h1(class: NAME_CLASS) { @tenant.name }
    end
  end

  def render_back_icon
    render Components::Icon.new(:chevron_left, stroke_width: "2.5", class: BACK_ICON_CLASS)
  end

  def render_service_step
    render_step("1", SERVICE_STEP) do
      div(class: SERVICE_ROW_CLASS) do
        div(class: SERVICE_TEXT_CLASS) do
          span(class: SERVICE_NAME_CLASS) { @service.name }
          span(class: SERVICE_META_CLASS) { ::Service::Duration.minutes_label(@service.duration_minutes) }
        end
        span(class: SERVICE_PRICE_CLASS, data: { price: true }) { price_label }
      end
    end
  end

  def render_step(number, title, &)
    div(class: STEP_CLASS) do
      div(class: STEP_LABEL_ROW_CLASS) do
        span(class: STEP_NUMBER_CLASS) { number }
        span(class: STEP_TITLE_CLASS) { title }
      end
      yield
    end
  end

  def render_published
    form_with(url: client_service_booking_path(@service), method: :post, class: "contents", data: {
      turbo: false, controller: "slot-selector submit-lock", submit_lock_label_value: "Confirmando…",
      action: SUBMIT_LOCK_ACTIONS
    }) do
      main(class: MAIN_CLASS) do
        render_service_step
        render_schedule_steps
      end
      input(type: "hidden", name: "starts_at", value: @selected_slot&.iso8601, data: { slot_selector_target: "input" })
      render_confirmation_bar
    end
  end

  def render_unpublished_main
    main(class: MAIN_CLASS) do
      render_service_step
      render_unpublished
    end
  end

  def render_schedule_steps
    div(class: "contents", data: { controller: "frame-cache", frame_cache_frame_value: Components::Client::Bookings::Grid::FRAME_ID }) do
      render_step("2", DAY_STEP) do
        render_day_selector
        p(class: HINT_CLASS, data: { days_off_hint: true }) { days_off_hint } if disabled_days.any?
      end
      render_step("3", TIME_STEP) do
        render Components::Client::Bookings::Grid.new(
          service: @service, slots: @slots, taken_slots: @taken_slots, reason: @reason, selected_slot: @selected_slot
        )
        p(class: SLOT_TAKEN_NOTICE_CLASS, hidden: true, role: "status",
          data: { slot_taken_notice: true, slot_selector_target: "takenNotice" }) { SLOT_TAKEN_NOTICE }
      end
    end
    render_data_step unless @signed_in
  end

  def render_day_selector
    render Components::DayStripOverflow.new(grid_from: :sm) do |strip|
      div(class: "#{SELECTOR_CLASS} #{strip.gutter}", data: {
        day_selector: true, controller: "day-selector",
        day_selector_selected_class: DAY_SELECTED_CLASS,
        day_selector_resting_class: DAY_FREE_CLASS,
        day_selector_weekday_resting_class: DAY_WEEKDAY_FREE_CLASS,
        frame_cache_target: "strip",
        **Components::DayStripOverflow::SCROLLER_DATA
      }) { @days.each { |date| render_day(date) } }
    end
  end

  def render_day(date)
    @reasons[date] == :bookable ? render_bookable_day(date) : render_disabled_day(date)
  end

  def render_bookable_day(date)
    selected = date == @selected_day
    a(href: new_client_service_booking_path(@service, day: date.iso8601),
      class: [ DAY_BASE_CLASS, selected ? DAY_SELECTED_CLASS : DAY_FREE_CLASS ],
      data: { day: date.iso8601, day_selector_target: selected ? "selected" : nil, turbo: true, turbo_prefetch: "false",
              turbo_frame: Components::Client::Bookings::Grid::FRAME_ID, turbo_action: "advance",
              day_label: day_label_for(date), action: "day-selector#mark slot-selector#resetDay" },
      aria_current: selected ? "date" : nil) do
      span(class: [ DAY_WEEKDAY_CLASS, (DAY_WEEKDAY_FREE_CLASS unless selected) ]) { Appointment::Labels::WEEKDAY_ABBR[date.wday] }
      span(class: DAY_NUMBER_CLASS) { date.strftime("%d") }
    end
  end

  def render_disabled_day(date)
    div(class: [ DAY_BASE_CLASS, DAY_DISABLED_CLASS ], data: { day: date.iso8601 }, aria_disabled: "true") do
      span(class: DAY_WEEKDAY_CLASS) { Appointment::Labels::WEEKDAY_ABBR[date.wday] }
      span(class: DAY_NUMBER_CLASS) { date.strftime("%d") }
    end
  end

  def disabled_days
    @days.reject { |date| @reasons[date] == :bookable }
  end

  def days_off_hint
    days = disabled_days
    days.one? ? Kernel.format(DAY_OFF_HINT, weekday: Appointment::Labels::WEEKDAY_NAMES[days.first.wday]) : DAYS_OFF_HINT
  end

  def render_unpublished
    p(class: UNPUBLISHED_CLASS) { UNPUBLISHED_MESSAGE }
  end

  def render_data_step
    render_step("4", DATA_STEP) do
      render_field(name: "name", caption: NAME_LABEL, placeholder: NAME_PLACEHOLDER, value: @client_name, errors: @name_errors)
      render_field(name: "phone", caption: PHONE_LABEL, placeholder: PHONE_PLACEHOLDER, value: @client_phone, errors: @phone_errors, inputmode: "tel")
      p(class: DATA_HINT_CLASS) { DATA_HINT }
    end
  end

  def render_field(name:, caption:, placeholder:, value:, errors:, inputmode: nil)
    div(class: FIELD_WRAPPER_CLASS, data: { field: name }) do
      label(class: FIELD_LABEL_CLASS) { caption }
      input(type: "text", name: name, value: value, placeholder: placeholder, inputmode: inputmode, class: FIELD_CLASS)
      render Components::Form::Errors.new(messages: errors)
    end
  end

  def render_confirmation_bar
    div(class: CONFIRM_BAR_CLASS) do
      div(class: CONFIRM_SUMMARY_CLASS) do
        span(class: SERVICE_NAME_CLASS) { @service.name }
        span(class: SERVICE_META_CLASS, data: { summary: true }) { render_summary }
      end
      button(type: "submit", disabled: @selected_slot.nil?, class: CONFIRM_BUTTON_CLASS,
        data: { confirm_bar: true, slot_selector_target: "submit", submit_lock_target: "button" }) { confirm_label }
    end
  end

  def render_summary
    span(data: { slot_selector_target: "day" }) { "#{day_label}#{SUMMARY_SEPARATOR}" }
    span(data: { slot_selector_target: "time" }) { "#{@selected_slot.strftime("%H:%M")}#{SUMMARY_SEPARATOR}" if @selected_slot }
    plain price_label
  end

  def day_label
    day_label_for(@selected_day)
  end

  def day_label_for(date)
    Appointment::Labels.day_label(date)
  end

  def confirm_label
    @selected_slot ? "#{CONFIRM_LABEL} #{@selected_slot.strftime("%H:%M")}" : CONFIRM_LABEL
  end

  def price_label
    ::Service::Price.compact_label(@service.public_price_cents)
  end
end
