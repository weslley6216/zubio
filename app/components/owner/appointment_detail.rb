class Components::Owner::AppointmentDetail < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  SHEET = Views::Client::Appointments::Show

  FRAME_ID = "appointment_detail".freeze

  TITLE = "Agendamento".freeze
  BACK_LABEL = "Voltar para a agenda".freeze
  CLOSE_LABEL = "Fechar".freeze
  CLIENT_HEADING = "Cliente".freeze
  SERVICE_HEADING = "Serviço".freeze
  DURATION_LABEL = "Duração".freeze
  WHATSAPP_LABEL = "Chamar no WhatsApp".freeze
  CALL_LABEL = "Ligar".freeze
  CANCEL_LABEL = "Desmarcar este horário".freeze
  CANCEL_NOTE = "O horário volta a aparecer livre na sua página. A %<name>s não é avisada sozinha: mande uma mensagem para ela.".freeze
  KEEP_LABEL = "Manter agendamento".freeze
  ATTEND_LABEL = "Atendi".freeze
  NO_SHOW_ACTION_LABEL = "Não veio".freeze
  SETTLE_BUTTON_CLASS = "min-h-[46px] flex-1 rounded-[10px] border border-line-strong bg-surface text-[14px] font-bold text-ink lg:min-h-11".freeze
  VISIT_LABEL = "%dª visita".freeze

  def initialize(appointment:, visit_number:)
    @appointment = appointment
    @visit_number = visit_number
  end

  def view_template
    section(class: "fixed inset-0 z-30 flex flex-col overflow-y-auto bg-canvas text-ink leading-[normal] lg:static lg:z-auto lg:gap-5 lg:overflow-visible lg:bg-surface lg:p-8",
      data: { appointment_id: @appointment.id }) do
      render_phone_header
      render_desktop_header
      render_body
    end
  end

  private

  def day_path = owner_appointments_path(day: @appointment.starts_at.to_date.iso8601)

  def frame_link_data = { turbo_frame: FRAME_ID, turbo_action: "advance" }

  def render_phone_header
    div(class: "flex items-center gap-3 border-b border-line bg-surface px-5 py-3.5 lg:hidden") do
      a(href: day_path, data: frame_link_data, aria_label: BACK_LABEL,
        class: "grid h-11 w-11 flex-none place-items-center rounded-[10px] border border-line") { render_back_icon }
      span(class: "flex-grow text-[16px] font-extrabold tracking-[-0.01em] text-ink") { TITLE }
    end
  end

  def render_back_icon
    render Components::Icon.new(:chevron_left, stroke_width: "2.5", class: "h-5 w-5")
  end

  def render_desktop_header
    div(class: "hidden items-center justify-between lg:flex") do
      span(class: "text-[13px] font-bold text-ink-muted") { TITLE }
      a(href: day_path, data: frame_link_data, aria_label: CLOSE_LABEL,
        class: "grid h-10 w-10 place-items-center rounded-[9px]") { render_close_icon }
    end
  end

  def render_close_icon
    render Components::Icon.new(:x, class: "h-5 w-5")
  end

  def render_body
    div(class: "flex flex-grow flex-col gap-4 p-5 lg:gap-5 lg:p-0") do
      render_time_card
      div(class: "hidden h-px bg-line lg:block")
      render_client_card
      render_actions
      render_cancel_footer if @appointment.cancellable?
      render_settle_footer if @appointment.settleable?
    end
  end

  def render_time_card
    div(class: "flex flex-col gap-1.5 rounded-2xl border border-line bg-surface p-5 shadow-[0_1px_2px_rgba(14,26,36,0.04)] lg:border-0 lg:p-0 lg:shadow-none") do
      div(class: "flex items-center gap-2.5") do
        span(class: "flex-grow text-[30px] font-extrabold tracking-[-0.02em] tabular-nums text-ink") { time_range }
        span(class: "flex-none rounded-full px-[9px] py-1 text-[11px] font-extrabold #{Components::Badge::TONES.fetch(badge.fetch(:tone))}") { badge.fetch(:label) }
      end
      span(class: "text-[14px] text-ink-muted") { render Components::LongDate.new(date: @appointment.starts_at.to_date) }
    end
  end

  def time_range = "#{@appointment.starts_at.strftime('%H:%M')} – #{@appointment.ends_at.strftime('%H:%M')}"

  def badge = Components::Owner::AppointmentRow::STATUS_BADGES.fetch(@appointment.status)

  def render_client_card
    div(class: "flex flex-col gap-3.5 rounded-2xl border border-line bg-surface px-5 py-[18px] lg:border-0 lg:gap-5 lg:px-0 lg:py-0") do
      span(class: "text-[11px] font-bold uppercase tracking-[0.08em] text-ink-muted") { CLIENT_HEADING }
      render_client_row
      div(class: "h-px bg-line")
      span(class: "text-[11px] font-bold uppercase tracking-[0.08em] text-ink-muted") { SERVICE_HEADING }
      render_service_row
      render_duration_row
    end
  end

  def render_client_row
    client = @appointment.client
    div(class: "flex items-center gap-3") do
      span(class: "grid h-11 w-11 flex-none place-items-center rounded-full bg-brand-soft text-[15px] font-extrabold text-brand-ink") { client.initials }
      div(class: "grid flex-grow gap-0.5") do
        span(class: "text-[16px] font-bold text-ink") { client.name }
        span(class: "text-[13px] tabular-nums text-ink-muted") { "#{client.phone_display} · #{Kernel.format(VISIT_LABEL, @visit_number)}" }
      end
    end
  end

  def render_service_row
    service = @appointment.service
    div(class: "flex items-baseline justify-between gap-4") do
      span(class: "flex-none text-[13px] text-ink-muted") { service.name }
      span(class: "text-right text-[14px] font-bold tabular-nums text-ink") { ::Service::Price.label(service.price_cents) }
    end
  end

  def render_duration_row
    service = @appointment.service
    div(class: "flex items-baseline justify-between gap-4") do
      span(class: "flex-none text-[13px] text-ink-muted") { DURATION_LABEL }
      span(class: "text-right text-[14px] font-bold tabular-nums text-ink") { ::Service::Duration.minutes_label(service.duration_minutes) }
    end
  end

  def render_actions
    client = @appointment.client
    div(class: "flex flex-col gap-2.5 lg:mt-1 lg:flex-row") do
      a(href: client.whatsapp_url, target: "_blank", rel: "noopener",
        class: "flex min-h-[50px] items-center justify-center gap-2 rounded-xl bg-brand-600 text-[15px] font-extrabold text-on-brand lg:min-h-11 lg:flex-grow lg:rounded-[10px] lg:text-[14px] lg:font-bold") do
        render_whatsapp_icon
        plain WHATSAPP_LABEL
      end
      a(href: client.tel_href,
        class: "flex min-h-[46px] w-full items-center justify-center gap-2 rounded-[10px] border border-line-strong bg-surface text-[14px] font-bold lg:hidden") do
        render_phone_icon
        plain CALL_LABEL
      end
    end
  end

  def render_whatsapp_icon
    render Components::Icon.new(:message_circle, class: "h-[18px] w-[18px]")
  end

  def render_phone_icon
    render Components::Icon.new(:phone, class: "h-[18px] w-[18px] lg:hidden")
  end

  def render_cancel_footer
    div(class: "mt-auto flex flex-col gap-2.5", data: { controller: "dialog" }) do
      button(type: "button", data: { action: "dialog#open" },
        class: "min-h-[46px] rounded-[10px] border border-danger bg-surface text-[14px] font-bold text-danger lg:min-h-11") { CANCEL_LABEL }
      span(class: "text-center text-[12px] leading-[1.5] text-ink-subtle lg:text-left") { Kernel.format(CANCEL_NOTE, name: @appointment.client.name.split.first) }
      render_sheet
    end
  end

  def render_sheet
    dialog(class: SHEET::SHEET_CLASS, data: { dialog_target: "sheet" }) do
      div(class: SHEET::GRABBER_CLASS)
      div(class: SHEET::SHEET_TEXT_CLASS) do
        span(class: SHEET::SHEET_TITLE_CLASS) { SHEET.confirm_prompt(@appointment) }
        span(class: SHEET::SHEET_NOTE_CLASS) { SHEET::CONFIRM_NOTE }
      end
      button_to(SHEET::CONFIRM_LABEL, owner_appointment_cancellation_path(@appointment), class: SHEET::CONFIRM_CLASS, form: agenda_frame_form)
      button(type: "button", class: SHEET::KEEP_CLASS, data: { action: "dialog#close" }) { KEEP_LABEL }
    end
  end

  def agenda_frame_form = { class: "contents", data: { turbo_frame: Components::Owner::AgendaDay::FRAME_ID, turbo_action: "advance" } }

  def render_settle_footer
    div(class: "mt-auto flex gap-2.5") do
      button_to(ATTEND_LABEL, owner_appointment_completion_path(@appointment), class: SETTLE_BUTTON_CLASS, form: agenda_frame_form) unless @appointment.completed?
      button_to(NO_SHOW_ACTION_LABEL, owner_appointment_no_show_path(@appointment), class: SETTLE_BUTTON_CLASS, form: agenda_frame_form) unless @appointment.no_show?
    end
  end
end
