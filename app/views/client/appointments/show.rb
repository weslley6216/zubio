class Views::Client::Appointments::Show < Views::Base
  ACTIVE_TITLE = "Seu horário".freeze
  CANCELLED_TITLE = "Horário desmarcado".freeze
  CANCELLED_SUBTITLE = "A %<professional>s já vê o horário livre na agenda dela.".freeze
  WHEN_LABEL = "Quando".freeze
  SERVICE_LABEL = "Serviço".freeze
  PRICE_LABEL = "Valor".freeze
  SCOPE_NOTE = "Este link mostra só este agendamento.".freeze
  REBOOK_LABEL = "Marcar outro horário".freeze
  CANCEL_LABEL = "Desmarcar este horário".freeze
  CONFIRM_PROMPT = "Desmarcar %<weekday>s, %<day>d %<month>s, às %<time>s?".freeze
  CONFIRM_NOTE = "O horário volta a ficar livre para outras pessoas. Não dá para desfazer.".freeze
  CONFIRM_LABEL = "Sim, desmarcar".freeze
  KEEP_LABEL = "Manter meu horário".freeze
  REOPEN_NOTE = "Se abrir este link de novo, você vê esta mesma tela.".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-surface-2 leading-[normal] text-ink".freeze
  BAND_CLASS = "flex items-center gap-3 bg-brand-600 px-5 py-3.5 text-on-brand".freeze
  BAND_NAME_CLASS = "min-w-0 flex-grow truncate text-[15px] font-extrabold tracking-[-0.01em]".freeze
  CONTENT_CLASS = "flex flex-grow flex-col gap-4 px-5 py-5".freeze
  HEADING_CLASS = "text-[22px] font-extrabold tracking-[-0.02em]".freeze
  CARD_CLASS = "flex flex-col gap-3.5 rounded-2xl border border-line bg-surface p-5".freeze
  ROW_CLASS = "flex items-baseline justify-between gap-4".freeze
  ROW_LABEL_CLASS = "flex-none text-[13px] text-ink-muted".freeze
  ROW_VALUE_CLASS = "text-right text-[14px] font-bold tabular-nums".freeze
  DIVIDER_CLASS = "h-px bg-line".freeze
  NOTE_CLASS = "text-[13px] leading-[1.5] text-ink-muted".freeze
  ACTIONS_CLASS = "flex flex-col gap-2.5".freeze
  REBOOK_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] border border-line-strong bg-surface text-[14px] font-bold text-ink".freeze
  CANCEL_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] border border-danger bg-surface text-[14px] font-bold text-danger".freeze

  SHEET_CLASS = "fixed inset-x-0 top-auto bottom-0 mx-auto w-full max-w-[430px] open:flex flex-col gap-3.5 rounded-t-[20px] border-0 bg-surface px-6 pt-3 pb-7 backdrop:bg-ink/45".freeze
  GRABBER_CLASS = "h-1 w-10 self-center rounded-full bg-line-strong".freeze
  SHEET_TEXT_CLASS = "flex flex-col gap-1.5".freeze
  SHEET_TITLE_CLASS = "text-[20px] font-extrabold tracking-[-0.02em] text-ink".freeze
  SHEET_NOTE_CLASS = "text-[14px] leading-[1.5] text-ink-muted".freeze
  CONFIRM_CLASS = "min-h-[50px] rounded-xl border-0 bg-danger text-[15px] font-extrabold text-on-danger".freeze
  KEEP_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] border border-line-strong bg-surface text-[14px] font-bold text-ink".freeze

  CANCELLED_ICON_WRAP_CLASS = "flex flex-col items-center gap-3.5 px-6 pt-11 pb-7 text-center".freeze
  CANCELLED_CIRCLE_CLASS = "grid h-16 w-16 place-items-center rounded-full bg-surface-3 text-ink-muted".freeze
  CANCELLED_ICON_CLASS = "h-[30px] w-[30px]".freeze
  CANCELLED_TEXT_CLASS = "flex flex-col gap-[5px]".freeze
  CANCELLED_SUBTITLE_CLASS = "text-[14px] text-ink-muted".freeze
  CANCELLED_CONTENT_CLASS = "flex flex-grow flex-col gap-4 px-5".freeze
  CANCELLED_CARD_CLASS = "flex flex-col gap-3 rounded-2xl border border-dashed border-line-strong bg-surface px-5 py-[18px]".freeze
  CANCELLED_VALUE_CLASS = "text-right text-[14px] font-bold tabular-nums text-ink-subtle line-through".freeze
  REBOOK_PRIMARY_CLASS = "grid min-h-[50px] place-items-center rounded-xl bg-brand-600 text-[15px] font-extrabold text-on-brand".freeze
  FOOTER_CLASS = "px-6 pb-7 text-center text-[12px] leading-[1.6] text-ink-subtle".freeze

  def initialize(tenant:, branding:, appointment:, service:, professional:)
    @tenant = tenant
    @branding = branding
    @appointment = appointment
    @service = service
    @professional = professional
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{page_title} · #{@tenant.name}", branding: @branding) do
      div(class: PAGE_CLASS, data: { appointment: true }) do
        render_band
        @appointment.cancelled? ? render_cancelled : render_scheduled
      end
    end
  end

  private

  def page_title = @appointment.cancelled? ? CANCELLED_TITLE : ACTIVE_TITLE

  def render_band
    div(class: BAND_CLASS) do
      render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :client, tone: :translucent)
      span(class: BAND_NAME_CLASS) { @tenant.name }
    end
  end

  def render_scheduled
    div(class: CONTENT_CLASS, data: scheduled_data) do
      h1(class: HEADING_CLASS) { ACTIVE_TITLE }
      render_detail_card
      span(class: NOTE_CLASS) { SCOPE_NOTE }
      div(class: ACTIONS_CLASS) do
        a(href: establishment_path, class: REBOOK_CLASS) { REBOOK_LABEL }
        a(href: new_client_cancellation_path(@appointment.cancel_token), class: CANCEL_CLASS, data: { action: "dialog#open" }) { CANCEL_LABEL } if @appointment.cancellable?
      end
      render_sheet if @appointment.cancellable?
    end
  end

  def scheduled_data = @appointment.cancellable? ? { controller: "dialog" } : {}

  def render_detail_card
    div(class: CARD_CLASS) do
      render_row(WHEN_LABEL, when_label)
      div(class: DIVIDER_CLASS)
      render_row(SERVICE_LABEL, @service.name)
      div(class: DIVIDER_CLASS)
      render_row(PRICE_LABEL, price_label)
    end
  end

  def render_row(label, value, value_class: ROW_VALUE_CLASS)
    div(class: ROW_CLASS) do
      span(class: ROW_LABEL_CLASS) { label }
      span(class: value_class) { value }
    end
  end

  def render_sheet
    dialog(class: SHEET_CLASS, data: { dialog_target: "sheet" }) do
      div(class: GRABBER_CLASS)
      div(class: SHEET_TEXT_CLASS) do
        span(class: SHEET_TITLE_CLASS) { confirm_prompt }
        span(class: SHEET_NOTE_CLASS) { CONFIRM_NOTE }
      end
      form_with(url: client_cancellation_path(@appointment.cancel_token), method: :post, class: "contents") do
        button(type: "submit", class: CONFIRM_CLASS) { CONFIRM_LABEL }
      end
      button(type: "button", class: KEEP_CLASS, data: { action: "dialog#close" }) { KEEP_LABEL }
    end
  end

  def render_cancelled
    div(class: CANCELLED_ICON_WRAP_CLASS) do
      div(class: CANCELLED_CIRCLE_CLASS) { render_cross_icon }
      div(class: CANCELLED_TEXT_CLASS) do
        span(class: HEADING_CLASS) { CANCELLED_TITLE }
        span(class: CANCELLED_SUBTITLE_CLASS) { cancelled_subtitle }
      end
    end
    div(class: CANCELLED_CONTENT_CLASS) do
      div(class: CANCELLED_CARD_CLASS) do
        render_row(WHEN_LABEL, when_label, value_class: CANCELLED_VALUE_CLASS)
        div(class: DIVIDER_CLASS)
        render_row(SERVICE_LABEL, @service.name, value_class: CANCELLED_VALUE_CLASS)
      end
      div(class: ACTIONS_CLASS) do
        a(href: establishment_path, class: REBOOK_PRIMARY_CLASS) { REBOOK_LABEL }
      end
    end
    p(class: FOOTER_CLASS) { REOPEN_NOTE }
  end

  def render_cross_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.4", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: CANCELLED_ICON_CLASS) do |icon|
      icon.path(d: "M6 6l12 12M18 6 6 18")
    end
  end

  def when_label
    date = @appointment.starts_at.to_date
    "#{Views::Client::Bookings::New::WEEKDAY_ABBR[date.wday].capitalize}, #{date.day} #{Views::Client::Bookings::New::MONTH_ABBR[date.month - 1]} · #{@appointment.starts_at.strftime("%H:%M")}"
  end

  def confirm_prompt
    date = @appointment.starts_at.to_date
    Kernel.format(CONFIRM_PROMPT, weekday: Views::Client::Bookings::New::WEEKDAY_NAMES[date.wday].downcase, day: date.day,
      month: Views::Client::Bookings::New::MONTH_ABBR[date.month - 1], time: @appointment.starts_at.strftime("%H:%M"))
  end

  def cancelled_subtitle = Kernel.format(CANCELLED_SUBTITLE, professional: @professional.display_name.split.first)

  def price_label = ::Service::Price.label(@service.public_price_cents)
end
