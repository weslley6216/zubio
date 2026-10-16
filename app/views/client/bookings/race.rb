class Views::Client::Bookings::Race < Views::Base
  ALERT_TITLE = "Alguém marcou %<time>s antes de você".freeze
  ALERT_BODY = "Seus dados continuam aqui. Escolha outro horário e confirme.".freeze
  SERVICE_LABEL = "Serviço".freeze
  DAY_LABEL = "Dia".freeze
  LEFTOVERS_LABEL = "Horários que sobraram".freeze
  NEAREST_HINT = "Já deixamos o mais perto marcado.".freeze
  NO_SLOTS_HINT = "Não sobrou nenhum horário livre neste dia.".freeze
  NAME_LABEL = "Nome".freeze
  PHONE_LABEL = "Celular".freeze
  CONFIRM_LABEL = "Confirmar".freeze
  ANOTHER_DAY_LABEL = "Escolher outro dia".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-surface-2 leading-[normal] text-ink".freeze
  HEADER_CLASS = "flex items-center gap-3 bg-brand-600 px-5 py-3.5 text-on-brand".freeze
  HEADER_NAME_CLASS = "min-w-0 flex-grow truncate text-[15px] font-extrabold tracking-[-0.01em]".freeze
  CONTENT_CLASS = "flex flex-grow flex-col gap-[18px] p-5".freeze
  ALERT_CLASS = "flex gap-3 rounded-xl border border-danger bg-surface px-4 py-3.5".freeze
  ALERT_ICON_CLASS = "h-5 w-5 flex-none text-danger".freeze
  ALERT_TEXT_CLASS = "flex flex-col gap-[3px]".freeze
  ALERT_TITLE_CLASS = "text-[14px] font-extrabold text-danger".freeze
  ALERT_BODY_CLASS = "text-[13px] leading-[1.5] text-ink-muted".freeze
  CARD_CLASS = "flex flex-col gap-2.5 rounded-xl border border-line bg-surface px-4 py-3.5".freeze
  CARD_ROW_CLASS = "flex items-baseline justify-between gap-4".freeze
  CARD_LABEL_CLASS = "flex-none text-[13px] text-ink-muted".freeze
  CARD_VALUE_CLASS = "text-right text-[14px] font-bold tabular-nums".freeze
  CARD_DIVIDER_CLASS = "h-px bg-line".freeze
  LEFTOVERS_CLASS = "flex flex-col gap-2.5".freeze
  LEFTOVERS_LABEL_CLASS = "text-[11px] font-bold uppercase tracking-[0.08em] text-ink-muted".freeze
  GRID_CLASS = "grid grid-cols-4 gap-2".freeze
  SLOT_BASE_CLASS = "grid min-h-[50px] place-items-center rounded-xl text-[15px] font-bold tabular-nums".freeze
  SLOT_FREE_CLASS = "border border-line bg-surface aria-pressed:border-transparent aria-pressed:bg-brand-600 aria-pressed:text-on-brand aria-pressed:shadow-[0_2px_6px_color-mix(in_srgb,var(--brand-600)_20%,transparent)]".freeze
  SLOT_TAKEN_CLASS = "border border-dashed border-line-strong bg-surface-3 text-ink-subtle line-through".freeze
  HINT_CLASS = "text-[12px] text-ink-subtle".freeze
  BAR_CLASS = "flex flex-col gap-2.5 px-5 pb-[calc(24px+env(safe-area-inset-bottom,0px))]".freeze
  BUTTON_CLASS = "flex min-h-[50px] w-full items-center justify-center gap-2 rounded-xl bg-brand-600 text-[15px] font-extrabold text-on-brand disabled:bg-surface-3 disabled:text-ink-muted".freeze
  ANOTHER_DAY_LINK_CLASS = "grid min-h-[46px] place-items-center rounded-xl border border-line bg-surface text-[14px] font-bold text-ink-muted".freeze

  def initialize(tenant:, branding:, service:, professional:, selected_day:, slots:, taken_slots:, nearest:, client_name:, client_phone:, lost_time:)
    @tenant = tenant
    @branding = branding
    @service = service
    @professional = professional
    @selected_day = selected_day
    @slots = slots
    @taken_slots = taken_slots
    @nearest = nearest
    @client_name = client_name
    @client_phone = client_phone
    @lost_time = lost_time
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding) do
      div(class: PAGE_CLASS) do
        render_header
        form_with(url: client_service_booking_path(@service), method: :post, class: "contents", data: { turbo: false, controller: "slot-selector" }) do
          div(class: CONTENT_CLASS) do
            render_alert
            render_detail_card
            render_leftovers
            render_client_card
          end
          input(type: "hidden", name: "starts_at", value: @nearest&.iso8601, data: { slot_selector_target: "input" })
          input(type: "hidden", name: "name", value: @client_name)
          input(type: "hidden", name: "phone", value: @client_phone)
          render_bar
        end
      end
    end
  end

  private

  def render_header
    header(class: HEADER_CLASS) do
      render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :client, tone: :translucent)
      span(class: HEADER_NAME_CLASS) { @tenant.name }
    end
  end

  def render_alert
    div(class: ALERT_CLASS, data: { alert: true }) do
      render_alert_icon
      div(class: ALERT_TEXT_CLASS) do
        span(class: ALERT_TITLE_CLASS) { Kernel.format(ALERT_TITLE, time: @lost_time.strftime("%H:%M")) }
        span(class: ALERT_BODY_CLASS) { ALERT_BODY }
      end
    end
  end

  def render_alert_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: ALERT_ICON_CLASS) do |icon|
      icon.circle(cx: "12", cy: "12", r: "9")
      icon.path(d: "M12 8v4M12 16h.01")
    end
  end

  def render_detail_card
    div(class: CARD_CLASS) do
      render_card_row(SERVICE_LABEL, @service.name)
      div(class: CARD_DIVIDER_CLASS)
      render_card_row(DAY_LABEL, day_label)
    end
  end

  def render_card_row(label, value)
    div(class: CARD_ROW_CLASS) do
      span(class: CARD_LABEL_CLASS) { label }
      span(class: CARD_VALUE_CLASS) { value }
    end
  end

  def day_label
    "#{Views::Client::Bookings::New::WEEKDAY_NAMES[@selected_day.wday]}, #{@selected_day.day} de #{Views::Client::Bookings::New::MONTH_NAMES[@selected_day.month - 1]}"
  end

  def render_leftovers
    div(class: LEFTOVERS_CLASS) do
      span(class: LEFTOVERS_LABEL_CLASS) { LEFTOVERS_LABEL }
      div(class: GRID_CLASS) do
        (@slots + @taken_slots).sort.each { |slot| @taken_slots.include?(slot) ? render_taken_slot(slot) : render_free_slot(slot) }
      end
      span(class: HINT_CLASS) { @nearest ? NEAREST_HINT : NO_SLOTS_HINT }
    end
  end

  def render_free_slot(slot)
    button(type: "button", aria_pressed: (slot == @nearest).to_s,
      data: { slot: true, starts_at: slot.iso8601, time: slot.strftime("%H:%M"), slot_selector_target: "slot", action: "slot-selector#select" },
      class: [ SLOT_BASE_CLASS, SLOT_FREE_CLASS ]) { slot.strftime("%H:%M") }
  end

  def render_taken_slot(slot)
    span(class: [ SLOT_BASE_CLASS, SLOT_TAKEN_CLASS ], data: { slot_taken: true, time: slot.strftime("%H:%M") }) { slot.strftime("%H:%M") }
  end

  def render_client_card
    div(class: CARD_CLASS) do
      render_card_row(NAME_LABEL, @client_name)
      div(class: CARD_DIVIDER_CLASS)
      render_card_row(PHONE_LABEL, @client_phone)
    end
  end

  def render_bar
    div(class: BAR_CLASS) do
      button(type: "submit", disabled: @nearest.nil?, class: BUTTON_CLASS, data: { confirm_bar: true, slot_selector_target: "submit" }) do
        @nearest ? "#{CONFIRM_LABEL} #{@nearest.strftime("%H:%M")}" : CONFIRM_LABEL
      end
      a(href: new_client_service_booking_path(@service), class: ANOTHER_DAY_LINK_CLASS, data: { another_day: true }) { ANOTHER_DAY_LABEL } unless @nearest
    end
  end
end
