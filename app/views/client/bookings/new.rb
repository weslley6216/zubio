class Views::Client::Bookings::New < Views::Base
  include Phlex::Rails::Helpers::TurboFrameTag

  FRAME_ID = "booking-grid".freeze
  WEEKDAY_ABBR = %w[DOM SEG TER QUA QUI SEX SÁB].freeze

  NO_SERVICE_MESSAGE = "Não há atendimento nesse dia.".freeze
  FULLY_BOOKED_MESSAGE = "Não há mais horários livres nesse dia.".freeze
  UNPUBLISHED_MESSAGE = "Este estabelecimento ainda não publicou horários.".freeze
  CONFIRM_LABEL = "Confirmar".freeze

  REASON_MESSAGES = {
    no_working_day: NO_SERVICE_MESSAGE,
    day_off: NO_SERVICE_MESSAGE,
    fully_booked: FULLY_BOOKED_MESSAGE
  }.freeze

  BAR_CLASS = "bg-brand-600 px-6 pb-8 pt-6 text-on-brand".freeze
  BAR_INNER_CLASS = "mx-auto flex w-full max-w-2xl items-center gap-3".freeze
  NAME_CLASS = "text-2xl font-extrabold tracking-tight".freeze
  MAIN_CLASS = "mx-auto grid w-full max-w-2xl gap-7 px-6 py-8".freeze
  STEP_CLASS = "grid gap-3".freeze
  STEP_LABEL_ROW_CLASS = "flex items-center gap-2.5".freeze
  STEP_NUMBER_CLASS = "grid h-6 w-6 place-items-center rounded-full bg-brand-100 text-xs font-extrabold text-brand-700".freeze
  STEP_TITLE_CLASS = "text-base font-bold tracking-tight text-ink".freeze
  SERVICE_ROW_CLASS = "flex items-center gap-2.5 rounded-xl border-2 border-brand bg-surface px-3.5 py-3.5 shadow-md".freeze
  SERVICE_NAME_CLASS = "text-sm font-bold text-ink".freeze
  SERVICE_META_CLASS = "text-xs text-ink-muted".freeze
  SERVICE_PRICE_CLASS = "ml-auto flex-none rounded-full bg-brand px-2.5 py-1.5 text-xs font-bold tabular-nums text-on-brand".freeze
  SELECTOR_CLASS = "flex gap-2 overflow-x-auto".freeze
  DAY_BASE_CLASS = "grid flex-1 shrink-0 basis-16 justify-items-center rounded-xl py-3".freeze
  DAY_SELECTED_CLASS = "bg-brand-600 text-on-brand shadow-md".freeze
  DAY_FREE_CLASS = "border border-line bg-surface text-ink".freeze
  DAY_DISABLED_CLASS = "border border-line bg-surface-3 text-ink-subtle".freeze
  DAY_WEEKDAY_CLASS = "text-[0.65rem] font-bold".freeze
  DAY_NUMBER_CLASS = "text-xl font-extrabold leading-tight tabular-nums".freeze
  GRID_CLASS = "grid grid-cols-4 gap-2".freeze
  SLOT_CLASS = "rounded-lg border border-line bg-surface py-3 text-center text-xs font-bold tabular-nums text-ink".freeze
  REASON_CLASS = "rounded-xl border border-line bg-surface-2 p-6 text-sm text-ink-muted".freeze
  UNPUBLISHED_CLASS = "grid gap-2 rounded-xl border border-line bg-surface p-6".freeze
  UNPUBLISHED_BODY_CLASS = "text-sm text-ink-muted".freeze
  CONFIRM_BAR_CLASS = "sticky bottom-0 flex items-center gap-3 border-t border-line bg-surface px-5 pb-[calc(1rem+env(safe-area-inset-bottom,0px))] pt-4".freeze
  CONFIRM_SUMMARY_CLASS = "grid gap-0.5".freeze
  CONFIRM_BUTTON_CLASS = "ml-auto flex-none rounded-lg bg-brand px-4 py-2.5 text-sm font-bold text-on-brand opacity-50".freeze

  def initialize(service:, tenant:, branding:, published:, days: [], reasons: {}, selected_day: nil, slots: [], reason: nil)
    @service = service
    @tenant = tenant
    @branding = branding
    @published = published
    @days = days
    @reasons = reasons
    @selected_day = selected_day
    @slots = slots
    @reason = reason
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding) do
      render_brand_bar
      main(class: MAIN_CLASS) do
        render_service_step
        @published ? render_time_step : render_unpublished
      end
      render_confirmation_bar if @published
    end
  end

  private

  def render_brand_bar
    header(class: BAR_CLASS) do
      div(class: BAR_INNER_CLASS) do
        render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :large)
        h1(class: NAME_CLASS) { @tenant.name }
      end
    end
  end

  def render_service_step
    div(class: STEP_CLASS) do
      render_step_label("1", "Serviço escolhido")
      div(class: SERVICE_ROW_CLASS) do
        div(class: "grid gap-0.5") do
          span(class: SERVICE_NAME_CLASS) { @service.name }
          span(class: SERVICE_META_CLASS) { ::Service::Duration.label(@service.duration_minutes) }
        end
        span(class: SERVICE_PRICE_CLASS) { ::Service::Price.label(@service.public_price_cents) }
      end
    end
  end

  def render_step_label(number, title)
    div(class: STEP_LABEL_ROW_CLASS) do
      span(class: STEP_NUMBER_CLASS) { number }
      span(class: STEP_TITLE_CLASS) { title }
    end
  end

  def render_time_step
    div(class: STEP_CLASS) do
      render_step_label("2", "Escolha o horário")
      turbo_frame_tag(FRAME_ID) do
        render_day_selector
        render_grid_or_reason
      end
    end
  end

  def render_day_selector
    div(class: SELECTOR_CLASS, data: { day_selector: true }) do
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
      data: { day: date.iso8601 },
      aria_current: selected ? "date" : nil) do
      render_day_face(date)
    end
  end

  def render_disabled_day(date)
    div(class: [ DAY_BASE_CLASS, DAY_DISABLED_CLASS ], data: { day: date.iso8601 }, aria_disabled: "true") do
      render_day_face(date)
    end
  end

  def render_day_face(date)
    span(class: DAY_WEEKDAY_CLASS) { WEEKDAY_ABBR[date.wday] }
    span(class: DAY_NUMBER_CLASS) { date.day.to_s }
  end

  def render_grid_or_reason
    @reason == :bookable ? render_grid : render_reason
  end

  def render_grid
    div(class: GRID_CLASS, data: { slots: true }) do
      @slots.each { |slot| span(class: SLOT_CLASS, data: { slot: true }) { slot.strftime("%H:%M") } }
    end
  end

  def render_reason
    p(class: REASON_CLASS) { REASON_MESSAGES.fetch(@reason) }
  end

  def render_unpublished
    div(class: UNPUBLISHED_CLASS) do
      p(class: UNPUBLISHED_BODY_CLASS) { UNPUBLISHED_MESSAGE }
    end
  end

  def render_confirmation_bar
    div(class: CONFIRM_BAR_CLASS) do
      div(class: CONFIRM_SUMMARY_CLASS) do
        span(class: SERVICE_NAME_CLASS) { @service.name }
        span(class: SERVICE_META_CLASS) { ::Service::Price.label(@service.public_price_cents) }
      end
      button(type: "button", disabled: true, class: CONFIRM_BUTTON_CLASS) { CONFIRM_LABEL }
    end
  end
end
