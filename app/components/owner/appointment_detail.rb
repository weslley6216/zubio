class Components::Owner::AppointmentDetail < Components::Base
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
  CANCEL_NOTE = "O horário volta a aparecer livre na sua página. Ninguém avisa a cliente sozinho: mande uma mensagem.".freeze
  CONFIRMED_LABEL = Components::Owner::AppointmentRow::CONFIRMED_LABEL
  CANCELLED_LABEL = Components::Owner::AppointmentRow::CANCELLED_LABEL
  VISIT_LABEL = "%dª visita".freeze

  def initialize(appointment:, visit_number:)
    @appointment = appointment
    @visit_number = visit_number
  end

  def view_template
    section(class: "fixed inset-0 z-30 flex flex-col overflow-y-auto bg-canvas text-ink leading-[normal] lg:static lg:z-auto lg:gap-5 lg:overflow-visible lg:bg-surface lg:p-8") do
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
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-5 w-5") { |icon| icon.path(d: "m15 6-6 6 6 6") }
  end

  def render_desktop_header
    div(class: "hidden items-center justify-between lg:flex") do
      span(class: "text-[13px] font-bold text-ink-muted") { TITLE }
      a(href: day_path, data: frame_link_data, aria_label: CLOSE_LABEL,
        class: "grid h-10 w-10 place-items-center rounded-[9px]") { render_close_icon }
    end
  end

  def render_close_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-5 w-5") { |icon| icon.path(d: "M6 6l12 12M18 6L6 18") }
  end

  def render_body
    div(class: "flex flex-grow flex-col gap-4 p-5 lg:gap-5 lg:p-0") do
      render_time_card
      div(class: "hidden h-px bg-line lg:block")
      render_client_card
      render_actions
      render_cancel_footer if @appointment.cancellable?
    end
  end

  def render_time_card
    div(class: "flex flex-col gap-1.5 rounded-2xl border border-line bg-surface p-5 shadow-[0_1px_2px_rgba(14,26,36,0.04)] lg:border-0 lg:p-0 lg:shadow-none") do
      div(class: "flex items-center gap-2.5") do
        span(class: "flex-grow text-[30px] font-extrabold tracking-[-0.02em] tabular-nums text-ink") { time_range }
        render Components::Badge.new(text: badge_label, tone: badge_tone)
      end
      span(class: "text-[14px] text-ink-muted") { render Components::LongDate.new(date: @appointment.starts_at.to_date) }
    end
  end

  def time_range = "#{@appointment.starts_at.strftime('%H:%M')} – #{@appointment.ends_at.strftime('%H:%M')}"

  def badge_label = @appointment.cancelled? ? CANCELLED_LABEL : CONFIRMED_LABEL

  def badge_tone = @appointment.cancelled? ? :muted : :brand

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
        class: "flex min-h-[46px] w-full items-center justify-center gap-2 rounded-[10px] border border-line-strong bg-surface text-[14px] font-bold lg:min-h-11 lg:w-auto lg:px-4") do
        render_phone_icon
        plain CALL_LABEL
      end
    end
  end

  def render_whatsapp_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-[18px] w-[18px]") { |icon| icon.path(d: "M21 11.5a8.4 8.4 0 0 1-8.5 8.4 8.5 8.5 0 0 1-4-1L4 20l1.1-4.4a8.4 8.4 0 0 1-1.1-4.1A8.4 8.4 0 0 1 12.5 3 8.4 8.4 0 0 1 21 11.5z") }
  end

  def render_phone_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-[18px] w-[18px] lg:hidden") { |icon| icon.path(d: "M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z") }
  end

  def render_cancel_footer
    div(class: "mt-auto flex flex-col gap-2.5") do
      button(type: "button",
        class: "min-h-[46px] rounded-[10px] border border-danger bg-surface text-[14px] font-bold text-danger lg:min-h-11") { CANCEL_LABEL }
      span(class: "text-center text-[12px] leading-[1.5] text-ink-subtle lg:text-left") { CANCEL_NOTE }
    end
  end
end
