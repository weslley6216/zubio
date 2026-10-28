class Views::Client::MyAppointments::Index < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  TITLE = "Meus agendamentos".freeze
  BACK_LABEL = "Voltar".freeze
  HINT = "Toque num horário para ver ou desmarcar.".freeze
  REBOOK_LABEL = "Marcar outro horário".freeze
  EMPTY_TITLE = "Você não tem horários marcados aqui".freeze
  EMPTY_SUBTITLE = "Os que você marcar na %s aparecem nesta lista.".freeze
  EMPTY_CTA_LABEL = "Marcar um horário".freeze
  FOOTER_LEAD = "Você entrou como".freeze
  SIGN_OUT_LABEL = "Sair".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-surface-2 leading-[normal] text-ink".freeze
  HEADER_CLASS = "flex items-center gap-3 bg-brand-600 px-5 py-3.5 text-on-brand".freeze
  BACK_CLASS = "grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-white/18".freeze
  BACK_ICON_CLASS = "h-5 w-5".freeze
  NAME_CLASS = "min-w-0 flex-grow truncate text-[15px] font-extrabold tracking-[-0.01em]".freeze

  MAIN_CLASS = "flex min-w-0 flex-grow flex-col gap-3.5 px-5 py-5".freeze
  HEADING_ROW_CLASS = "flex items-baseline gap-2.5".freeze
  HEADING_CLASS = "flex-grow text-[22px] font-extrabold tracking-[-0.02em]".freeze
  COUNT_CLASS = "text-[13px] font-bold text-ink-muted tabular-nums".freeze
  LIST_CLASS = "flex flex-col gap-2.5".freeze
  ITEM_CLASS = "relative flex min-h-[44px] items-center gap-3 rounded-xl border border-line bg-surface px-4 py-3.5 shadow-[0_1px_2px_rgba(14,26,36,0.04)] hover:bg-surface-2".freeze
  ITEM_WHEN_CLASS = "flex w-12 flex-none flex-col items-center".freeze
  ITEM_TIME_CLASS = "text-[16px] font-extrabold leading-[1.2] tabular-nums".freeze
  ITEM_DURATION_CLASS = "text-[11px] text-ink-muted tabular-nums".freeze
  ITEM_DIVIDER_CLASS = "w-px flex-none self-stretch bg-line".freeze
  ITEM_DETAIL_CLASS = "flex min-w-0 flex-grow flex-col gap-1".freeze
  ITEM_DAY_CLASS = "text-[14px] font-bold tabular-nums".freeze
  ITEM_SERVICE_CLASS = "text-[12px] text-ink-muted".freeze
  ITEM_CHEVRON_CLASS = "h-[18px] w-[18px] flex-none text-brand-600".freeze
  HINT_CLASS = "text-[12px] text-ink-subtle".freeze
  REBOOK_CLASS = "flex min-h-[46px] w-full items-center justify-center gap-2 rounded-[10px] border border-line-strong bg-surface text-[14px] font-bold text-ink".freeze

  EMPTY_CLASS = "flex flex-grow flex-col items-center gap-3.5 px-6 pt-14 pb-7 text-center".freeze
  EMPTY_ICON_WRAP_CLASS = "grid h-16 w-16 place-items-center rounded-full bg-surface-3".freeze
  EMPTY_ICON_CLASS = "h-[30px] w-[30px] text-ink-muted".freeze
  EMPTY_TEXT_CLASS = "flex flex-col gap-[5px]".freeze
  EMPTY_TITLE_CLASS = "text-[22px] font-extrabold tracking-[-0.02em]".freeze
  EMPTY_SUBTITLE_CLASS = "text-[14px] text-ink-muted".freeze
  EMPTY_CTA_CLASS = "mt-2 flex min-h-[50px] w-full items-center justify-center gap-2 rounded-xl bg-brand-600 text-[15px] font-extrabold text-on-brand".freeze

  FOOTER_CLASS = "mx-5 mb-6 flex items-center gap-3 rounded-xl border border-line bg-surface py-3 pr-3 pl-4".freeze
  FOOTER_TEXT_CLASS = "flex min-w-0 flex-grow flex-col gap-0.5".freeze
  FOOTER_LEAD_CLASS = "text-[12px] text-ink-muted".freeze
  FOOTER_EMAIL_CLASS = "text-[14px] font-bold".freeze
  SIGN_OUT_CLASS = "min-h-[44px] flex-none rounded-[10px] border border-line-strong bg-surface px-3.5 text-[13px] font-bold text-ink".freeze

  def initialize(tenant:, branding:, appointments:, client:)
    @tenant = tenant
    @branding = branding
    @appointments = appointments
    @client = client
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding) do
      div(class: PAGE_CLASS) do
        render_header
        @appointments.empty? ? render_empty_state : render_list
        render_footer
      end
    end
  end

  private

  def render_header
    header(class: HEADER_CLASS) do
      a(href: establishment_path, class: BACK_CLASS, aria_label: BACK_LABEL) { render_back_icon }
      h2(class: NAME_CLASS) { @tenant.name }
    end
  end

  def render_back_icon
    render Components::Icon.new(:chevron_left, stroke_width: "2.5", class: BACK_ICON_CLASS)
  end

  def render_list
    main(class: MAIN_CLASS) do
      div(class: HEADING_ROW_CLASS) do
        h1(class: HEADING_CLASS) { TITLE }
        span(class: COUNT_CLASS) { count_label }
      end
      div(class: LIST_CLASS) { @appointments.each { |appointment| render_item(appointment) } }
      span(class: HINT_CLASS) { HINT }
      a(href: establishment_path, class: REBOOK_CLASS, data: { rebook_link: true }) { REBOOK_LABEL }
    end
  end

  def count_label
    count = @appointments.size
    "#{count} #{count == 1 ? "próximo" : "próximos"}"
  end

  def render_item(appointment)
    a(href: client_appointment_path(appointment.cancel_token, from: "list"), class: ITEM_CLASS, data: { my_appointment: true }) do
      div(class: ITEM_WHEN_CLASS) do
        span(class: ITEM_TIME_CLASS) { appointment.starts_at.strftime("%H:%M") }
        span(class: ITEM_DURATION_CLASS) { ::Service::Duration.minutes_label(appointment.service.duration_minutes) }
      end
      div(class: ITEM_DIVIDER_CLASS)
      div(class: ITEM_DETAIL_CLASS) do
        span(class: ITEM_DAY_CLASS) { day_label(appointment) }
        span(class: ITEM_SERVICE_CLASS) { appointment.service.name }
      end
      render_chevron_icon
    end
  end

  def day_label(appointment)
    date = appointment.starts_at.to_date
    "#{Views::Client::Bookings::New::WEEKDAY_ABBR[date.wday].capitalize}, #{date.day} #{Views::Client::Bookings::New::MONTH_ABBR[date.month - 1]}"
  end

  def render_chevron_icon
    render Components::Icon.new(:chevron_right, stroke_width: "2.5", class: ITEM_CHEVRON_CLASS)
  end

  def render_empty_state
    div(class: EMPTY_CLASS) do
      div(class: EMPTY_ICON_WRAP_CLASS) { render_calendar_icon }
      div(class: EMPTY_TEXT_CLASS) do
        h1(class: EMPTY_TITLE_CLASS) { EMPTY_TITLE }
        span(class: EMPTY_SUBTITLE_CLASS) { EMPTY_SUBTITLE % @tenant.name }
      end
      a(href: establishment_path, class: EMPTY_CTA_CLASS, data: { rebook_link: true }) { EMPTY_CTA_LABEL }
    end
  end

  def render_calendar_icon
    render Components::Icon.new(:calendar, stroke_width: "2.2", class: EMPTY_ICON_CLASS)
  end

  def render_footer
    div(class: FOOTER_CLASS) do
      div(class: FOOTER_TEXT_CLASS) do
        span(class: FOOTER_LEAD_CLASS) { FOOTER_LEAD }
        span(class: FOOTER_EMAIL_CLASS) { @client.masked_email }
      end
      button_to(SIGN_OUT_LABEL, client_session_path, method: :delete, class: SIGN_OUT_CLASS)
    end
  end
end
