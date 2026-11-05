class Views::Client::Appointments::Show < Views::Base
  ACTIVE_TITLE = "Seu horário".freeze
  CANCELLED_TITLE = "Horário desmarcado".freeze
  CANCELLED_SUBTITLE = "A %<professional>s já vê o horário livre na agenda dela.".freeze
  WHEN_LABEL = "Quando".freeze
  SERVICE_LABEL = "Serviço".freeze
  PRICE_LABEL = "Valor".freeze
  BACK_LABEL = "Voltar".freeze
  REBOOK_LABEL = "Marcar outro horário".freeze
  CANCEL_LABEL = "Desmarcar este horário".freeze
  CONFIRM_PROMPT = "Desmarcar %<weekday>s, %<day>d %<month>s, às %<time>s?".freeze
  CONFIRM_NOTE = "O horário volta a ficar livre para outras pessoas. Não dá para desfazer.".freeze
  CONFIRM_LABEL = "Sim, desmarcar".freeze
  KEEP_LABEL = "Manter meu horário".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-(--theme-bg) leading-[normal] text-(--theme-on-bg)".freeze
  BAND_CLASS = "flex items-center gap-3 px-5 py-3.5".freeze
  BACK_CLASS = "grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-(--theme-bg-tint)".freeze
  BACK_ICON_CLASS = "h-5 w-5".freeze
  BAND_NAME_CLASS = "min-w-0 flex-grow truncate text-[15px] font-extrabold tracking-[-0.01em]".freeze
  CONTENT_CLASS = "flex flex-grow flex-col gap-4 px-5 py-5".freeze
  HEADING_CLASS = "text-[22px] font-extrabold tracking-[-0.02em]".freeze
  CARD_CLASS = "flex flex-col gap-3.5 rounded-2xl border border-(--theme-card-line) bg-(--theme-card) p-5 text-(--theme-on-card)".freeze
  ROW_CLASS = "flex items-baseline justify-between gap-4".freeze
  ROW_LABEL_CLASS = "flex-none text-[13px] text-(--theme-on-card-muted)".freeze
  ROW_VALUE_CLASS = "text-right text-[14px] font-bold tabular-nums".freeze
  DIVIDER_CLASS = "h-px bg-(--theme-card-line)".freeze
  ACTIONS_CLASS = "flex flex-col gap-2.5".freeze
  REBOOK_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] border border-(--theme-ghost) text-[14px] font-bold text-(--theme-on-bg)".freeze
  CANCEL_CLASS = "grid min-h-[46px] place-items-center rounded-[10px] border border-(--theme-danger-line-on-bg) text-[14px] font-bold text-(--theme-danger-on-bg)".freeze

  SHEET_CLASS = "#{Views::Client::Appointments::SheetFrame::SHEET_CLASS} bg-(--theme-card)".freeze
  GRABBER_CLASS = Views::Client::Appointments::SheetFrame::GRABBER_CLASS
  SHEET_TEXT_CLASS = Views::Client::Appointments::SheetFrame::TEXT_CLASS
  SHEET_TITLE_CLASS = "#{Views::Client::Appointments::SheetFrame::TITLE_CLASS} text-(--theme-on-card)".freeze
  SHEET_NOTE_CLASS = "#{Views::Client::Appointments::SheetFrame::NOTE_CLASS} text-(--theme-on-card-muted)".freeze
  CONFIRM_CLASS = "#{Views::Client::Appointments::SheetFrame::CONFIRM_CLASS} bg-(--theme-danger-on-card) text-(--theme-card)".freeze
  KEEP_CLASS = "#{Views::Client::Appointments::SheetFrame::KEEP_CLASS} border-(--theme-card-line) text-(--theme-on-card)".freeze

  CANCELLED_ICON_WRAP_CLASS = "flex flex-col items-center gap-3.5 px-6 pt-11 pb-7 text-center".freeze
  CANCELLED_CIRCLE_CLASS = "grid h-16 w-16 place-items-center rounded-full bg-(--theme-bg-tint) text-(--theme-on-bg-muted)".freeze
  CANCELLED_ICON_CLASS = "h-[30px] w-[30px]".freeze
  CANCELLED_TEXT_CLASS = "flex flex-col gap-[5px]".freeze
  CANCELLED_SUBTITLE_CLASS = "text-[14px] text-(--theme-on-bg-muted)".freeze
  CANCELLED_CONTENT_CLASS = "flex flex-grow flex-col gap-4 px-5".freeze
  CANCELLED_CARD_CLASS = "flex flex-col gap-3 rounded-2xl border border-dashed border-(--theme-card-line) bg-(--theme-card) px-5 py-[18px] text-(--theme-on-card)".freeze
  CANCELLED_VALUE_CLASS = "text-right text-[14px] font-bold tabular-nums text-(--theme-on-card-muted) line-through".freeze
  REBOOK_PRIMARY_CLASS = "grid min-h-[50px] place-items-center rounded-xl bg-(--theme-accent) text-[15px] font-extrabold text-(--theme-on-accent)".freeze

  def self.confirm_prompt(appointment)
    date = appointment.starts_at.to_date
    Kernel.format(CONFIRM_PROMPT, weekday: Appointment::Labels::WEEKDAY_NAMES[date.wday].downcase, day: date.day,
      month: Appointment::Labels::MONTH_ABBR[date.month - 1], time: appointment.starts_at.strftime("%H:%M"))
  end

  def initialize(tenant:, branding:, appointment:, service:, professional:, back_to_list: false)
    @tenant = tenant
    @branding = branding
    @appointment = appointment
    @service = service
    @professional = professional
    @back_to_list = back_to_list
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
      @appointment.cancelled? ? render_emblem : render_back_link
      span(class: BAND_NAME_CLASS) { @tenant.name }
    end
  end

  def render_emblem
    render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :client, tone: :translucent)
  end

  def render_back_link
    a(href: back_href, class: BACK_CLASS, aria_label: BACK_LABEL) { render_back_icon }
  end

  def render_back_icon
    render Components::Icon.new(:chevron_left, stroke_width: "2.5", class: BACK_ICON_CLASS)
  end

  def back_href = @back_to_list ? client_my_appointments_path : establishment_path

  def render_scheduled
    div(class: CONTENT_CLASS, data: scheduled_data) do
      h1(class: HEADING_CLASS) { ACTIVE_TITLE }
      render_detail_card
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
  end

  def render_cross_icon
    render Components::Icon.new(:x, stroke_width: "2.4", class: CANCELLED_ICON_CLASS)
  end

  def when_label = labels.when_label

  def confirm_prompt = self.class.confirm_prompt(@appointment)

  def cancelled_subtitle = Kernel.format(CANCELLED_SUBTITLE, professional: @professional.display_name.split.first)

  def price_label = labels.price_label

  def labels = @labels ||= Appointment::Labels.new(@appointment)
end
