class Views::Client::Bookings::New < Views::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  FRAME_ID = "booking-grid".freeze
  WEEKDAY_ABBR = %w[DOM SEG TER QUA QUI SEX SÁB].freeze
  WEEKDAY_NAMES = %w[Domingo Segunda Terça Quarta Quinta Sexta Sábado].freeze
  MONTH_ABBR = %w[jan fev mar abr mai jun jul ago set out nov dez].freeze

  BACK_LABEL = "Voltar".freeze
  SERVICE_STEP = "Serviço".freeze
  DAY_STEP = "Dia".freeze
  TIME_STEP = "Horário".freeze
  DAYS_OFF_HINT = "Dias em cinza: sem horário livre.".freeze
  TAKEN_LABEL = "ocupado".freeze
  NO_SERVICE_MESSAGE = "Não há atendimento nesse dia.".freeze
  FULLY_BOOKED_MESSAGE = "Não há mais horários livres nesse dia.".freeze
  UNPUBLISHED_MESSAGE = "Este estabelecimento ainda não publicou horários.".freeze
  CONFIRM_LABEL = "Confirmar".freeze
  SUMMARY_SEPARATOR = " · ".freeze

  REASON_MESSAGES = {
    no_working_day: NO_SERVICE_MESSAGE,
    day_off: NO_SERVICE_MESSAGE,
    fully_booked: FULLY_BOOKED_MESSAGE
  }.freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-surface-2 leading-[normal] text-ink".freeze
  HEADER_CLASS = "flex items-center gap-3 bg-brand-600 px-5 py-3.5 text-on-brand".freeze
  BACK_CLASS = "grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-white/18".freeze
  BACK_ICON_CLASS = "h-5 w-5".freeze
  NAME_CLASS = "min-w-0 flex-grow truncate text-[15px] font-extrabold tracking-[-0.01em]".freeze
  MAIN_CLASS = "flex min-w-0 flex-grow flex-col gap-[22px] px-5 pt-[22px] pb-[120px]".freeze
  FRAME_CLASS = "contents".freeze
  STEP_CLASS = "flex min-w-0 flex-col gap-2.5".freeze
  STEP_LABEL_ROW_CLASS = "flex items-center gap-2.5".freeze
  STEP_NUMBER_CLASS = "grid h-6 w-6 place-items-center rounded-full bg-brand-100 text-[12px] font-extrabold text-brand-800".freeze
  STEP_TITLE_CLASS = "text-[15px] font-extrabold tracking-[-0.01em]".freeze
  SERVICE_ROW_CLASS = "flex items-center gap-3 rounded-xl border-2 border-brand-600 bg-surface px-4 py-3.5 shadow-[0_2px_6px_color-mix(in_srgb,var(--brand-600)_12%,transparent)]".freeze
  SERVICE_TEXT_CLASS = "flex min-w-0 flex-grow flex-col gap-0.5".freeze
  SERVICE_NAME_CLASS = "text-[14px] font-bold".freeze
  SERVICE_META_CLASS = "text-[12px] tabular-nums text-ink-muted".freeze
  SERVICE_PRICE_CLASS = "flex-none rounded-full bg-brand-600 px-3 py-[7px] text-[13px] font-extrabold tabular-nums text-on-brand".freeze
  SELECTOR_CLASS = "flex snap-x snap-mandatory gap-2 overflow-x-auto overscroll-x-contain [scrollbar-width:none] sm:grid sm:grid-cols-7 sm:overflow-visible [&::-webkit-scrollbar]:hidden".freeze
  DAY_BASE_CLASS = "flex shrink-0 basis-[calc((100%-1.5rem)/4)] snap-start flex-col items-center gap-px rounded-xl py-3".freeze
  DAY_SELECTED_CLASS = "bg-brand-600 text-on-brand shadow-[0_2px_6px_color-mix(in_srgb,var(--brand-600)_20%,transparent)]".freeze
  DAY_FREE_CLASS = "border border-line bg-surface".freeze
  DAY_DISABLED_CLASS = "border border-dashed border-line-strong bg-surface-2 text-ink-subtle".freeze
  DAY_WEEKDAY_CLASS = "text-[10px] font-bold tracking-[0.04em]".freeze
  DAY_WEEKDAY_FREE_CLASS = "text-ink-muted".freeze
  DAY_NUMBER_CLASS = "text-[20px] leading-[1.15] font-extrabold tabular-nums".freeze
  HINT_CLASS = "text-[12px] text-ink-subtle".freeze
  GRID_CLASS = "grid grid-cols-4 gap-2".freeze
  SLOT_BASE_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] text-[13px] font-bold tabular-nums".freeze
  SLOT_FREE_CLASS = "border border-line bg-surface".freeze
  SLOT_TAKEN_CLASS = "border border-dashed border-line-strong bg-surface-3 text-ink-subtle line-through".freeze
  REASON_CLASS = "rounded-xl border border-line bg-surface p-6 text-[14px] text-ink-muted".freeze
  UNPUBLISHED_CLASS = "rounded-xl border border-line bg-surface p-6 text-[14px] text-ink-muted".freeze
  CONFIRM_BAR_CLASS = "sticky bottom-0 -mt-[100px] flex items-center gap-3 border-t border-line bg-surface px-5 pt-3.5 pb-[calc(18px+env(safe-area-inset-bottom,0px))] shadow-[0_-4px_16px_rgba(14,26,36,0.06)]".freeze
  CONFIRM_SUMMARY_CLASS = "flex min-w-0 flex-grow flex-col gap-0.5".freeze
  CONFIRM_BUTTON_CLASS = "min-h-[46px] flex-none rounded-[10px] bg-brand-600 px-5 text-[15px] font-extrabold text-on-brand disabled:bg-surface-3 disabled:text-ink-muted".freeze

  def initialize(service:, tenant:, branding:, published:, days: [], reasons: {}, selected_day: nil, slots: [], taken_slots: [], reason: nil)
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
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding) do
      div(class: PAGE_CLASS) do
        render_header
        turbo_frame_tag(FRAME_ID, class: FRAME_CLASS) do
          main(class: MAIN_CLASS) do
            render_service_step
            @published ? render_schedule_steps : render_unpublished
          end
          render_confirmation_bar if @published
        end
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
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BACK_ICON_CLASS) do |icon|
      icon.path(d: "m15 6-6 6 6 6")
    end
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

  def render_schedule_steps
    render_step("2", DAY_STEP) do
      render_day_selector
      p(class: HINT_CLASS, data: { days_off_hint: true }) { days_off_hint } if disabled_days.any?
    end
    render_step("3", TIME_STEP) { render_grid_or_reason }
  end

  def render_day_selector
    div(class: SELECTOR_CLASS, data: { day_selector: true, controller: "day-selector" }) do
      @days.each { |date| render_day(date) }
    end
  end

  def render_day(date)
    @reasons[date] == :bookable ? render_bookable_day(date) : render_disabled_day(date)
  end

  def render_bookable_day(date)
    selected = date == @selected_day
    a(href: new_client_service_booking_path(@service, day: date.iso8601),
      class: [ DAY_BASE_CLASS, selected ? DAY_SELECTED_CLASS : DAY_FREE_CLASS ],
      data: { day: date.iso8601, day_selector_target: selected ? "selected" : nil },
      aria_current: selected ? "date" : nil) do
      span(class: [ DAY_WEEKDAY_CLASS, (DAY_WEEKDAY_FREE_CLASS unless selected) ]) { WEEKDAY_ABBR[date.wday] }
      span(class: DAY_NUMBER_CLASS) { date.strftime("%d") }
    end
  end

  def render_disabled_day(date)
    div(class: [ DAY_BASE_CLASS, DAY_DISABLED_CLASS ], data: { day: date.iso8601 }, aria_disabled: "true") do
      span(class: DAY_WEEKDAY_CLASS) { WEEKDAY_ABBR[date.wday] }
      span(class: DAY_NUMBER_CLASS) { date.strftime("%d") }
    end
  end

  def disabled_days
    @days.reject { |date| @reasons[date] == :bookable }
  end

  def days_off_hint
    days = disabled_days
    days.one? ? "#{WEEKDAY_NAMES[days.first.wday]} está em cinza: sem horário livre." : DAYS_OFF_HINT
  end

  def render_grid_or_reason
    @reason == :bookable ? render_grid : render_reason
  end

  def render_grid
    div(class: GRID_CLASS, data: { slots: true }) do
      (@slots + @taken_slots).sort.each { |slot| @taken_slots.include?(slot) ? render_taken_slot(slot) : render_free_slot(slot) }
    end
    p(class: HINT_CLASS, data: { grid_hint: true }) { grid_hint }
  end

  def render_free_slot(slot)
    span(class: [ SLOT_BASE_CLASS, SLOT_FREE_CLASS ], data: { slot: true }) { slot.strftime("%H:%M") }
  end

  def render_taken_slot(slot)
    time = slot.strftime("%H:%M")
    span(class: [ SLOT_BASE_CLASS, SLOT_TAKEN_CLASS ], data: { slot_taken: true }, aria_label: "#{time}, #{TAKEN_LABEL}") { time }
  end

  def grid_hint
    minutes = @service.duration_minutes
    "A grade anda de #{minutes} em #{minutes} porque o serviço dura #{minutes}."
  end

  def render_reason
    p(class: REASON_CLASS) { REASON_MESSAGES.fetch(@reason) }
  end

  def render_unpublished
    p(class: UNPUBLISHED_CLASS) { UNPUBLISHED_MESSAGE }
  end

  def render_confirmation_bar
    div(class: CONFIRM_BAR_CLASS) do
      div(class: CONFIRM_SUMMARY_CLASS) do
        span(class: SERVICE_NAME_CLASS) { @service.name }
        span(class: SERVICE_META_CLASS, data: { summary: true }) { summary }
      end
      button(type: "button", disabled: true, class: CONFIRM_BUTTON_CLASS, data: { confirm_bar: true }) { CONFIRM_LABEL }
    end
  end

  def summary
    day = "#{WEEKDAY_ABBR[@selected_day.wday].capitalize}, #{@selected_day.day} #{MONTH_ABBR[@selected_day.month - 1]}"
    [ day, price_label ].join(SUMMARY_SEPARATOR)
  end

  def price_label
    ::Service::Price.compact_label(@service.public_price_cents)
  end
end
