class Views::Client::MyAppointments::Index < Views::Base
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::TurboStreamFrom

  TITLE = "Meus agendamentos".freeze
  BACK_LABEL = "Voltar".freeze
  HINT = "Toque num horário para ver ou desmarcar.".freeze
  REBOOK_LABEL = "Marcar outro horário".freeze
  EMPTY_TITLE = "Você não tem horários marcados aqui".freeze
  EMPTY_SUBTITLE = "Os que você marcar na %s aparecem nesta lista.".freeze
  EMPTY_CTA_LABEL = "Marcar um horário".freeze
  FOOTER_LEAD = "Você entrou como".freeze
  SIGN_OUT_LABEL = "Sair".freeze

  PAGE_CLASS = Views::Client::Frame::PAGE
  HEADER_CLASS = Views::Client::Frame::HEADER
  BACK_CLASS = Views::Client::Frame::BACK
  BACK_ICON_CLASS = Views::Client::Frame::BACK_ICON
  NAME_CLASS = Views::Client::Frame::NAME

  MAIN_CLASS = "flex min-w-0 flex-grow flex-col gap-3 px-5 pt-2 pb-5".freeze
  HEADING_ROW_CLASS = "flex items-baseline gap-2.5".freeze
  HEADING_CLASS = "flex-grow text-[22px] font-extrabold tracking-[-0.02em]".freeze
  COUNT_CLASS = "text-[13px] font-bold text-(--theme-on-bg-muted) tabular-nums".freeze
  LIST_CLASS = "flex flex-col gap-3".freeze
  ITEM_CLASS = "relative flex min-h-[44px] items-center gap-3 rounded-2xl bg-(--theme-card) p-3.5 text-(--theme-on-card)".freeze
  ITEM_WHEN_CLASS = "flex w-12 flex-none flex-col items-center".freeze
  ITEM_TIME_CLASS = "text-[16px] leading-[normal] font-extrabold whitespace-nowrap tabular-nums".freeze
  ITEM_DURATION_CLASS = "text-[11px] whitespace-nowrap text-(--theme-on-card-muted)".freeze
  ITEM_DIVIDER_CLASS = "w-px flex-none self-stretch bg-(--theme-card-line)".freeze
  ITEM_DETAIL_CLASS = "flex min-w-0 flex-grow flex-col gap-[3px]".freeze
  ITEM_DAY_CLASS = "text-[14px] font-extrabold tabular-nums".freeze
  ITEM_SERVICE_CLASS = "text-[12px] text-(--theme-on-card-muted)".freeze
  ITEM_CHEVRON_CLASS = "h-[18px] w-[18px] flex-none text-(--theme-on-card-muted)".freeze
  HINT_CLASS = "text-[12px] text-(--theme-on-bg-muted)".freeze
  REBOOK_CLASS = "flex min-h-12 w-full items-center justify-center gap-2 rounded-xl border border-(--theme-ghost) text-[14px] font-bold text-(--theme-on-bg)".freeze

  EMPTY_CLASS = "flex flex-grow flex-col items-center gap-3.5 px-6 pt-14 pb-7 text-center".freeze
  EMPTY_ICON_WRAP_CLASS = "grid h-16 w-16 place-items-center rounded-full bg-(--theme-bg-tint)".freeze
  EMPTY_ICON_CLASS = "h-[30px] w-[30px] text-(--theme-on-bg-muted)".freeze
  EMPTY_TEXT_CLASS = "flex flex-col gap-[5px]".freeze
  EMPTY_TITLE_CLASS = "text-[22px] font-extrabold tracking-[-0.02em]".freeze
  EMPTY_SUBTITLE_CLASS = "text-[14px] text-(--theme-on-bg-muted)".freeze
  EMPTY_CTA_CLASS = "mt-2 flex min-h-[50px] w-full items-center justify-center gap-2 rounded-xl bg-(--theme-accent) text-[15px] font-extrabold text-(--theme-on-accent)".freeze

  FOOTER_CLASS = "mx-5 mb-6 flex items-center gap-3 rounded-2xl bg-(--theme-card) py-3 pr-3 pl-4 text-(--theme-on-card)".freeze
  FOOTER_TEXT_CLASS = "flex min-w-0 flex-grow flex-col gap-0.5".freeze
  FOOTER_LEAD_CLASS = "text-[12px] text-(--theme-on-card-muted)".freeze
  FOOTER_EMAIL_CLASS = "text-[14px] font-extrabold".freeze
  SIGN_OUT_CLASS = "min-h-[46px] flex-none rounded-[10px] border border-(--theme-card-line) px-3.5 text-[13px] font-bold text-(--theme-on-card)".freeze

  def initialize(tenant:, branding:, appointments:, client:, app_installed: false)
    @tenant = tenant
    @branding = branding
    @appointments = appointments
    @client = client
    @app_installed = app_installed
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding, page_refresh: :morph) do
      div(class: PAGE_CLASS) do
        div(data: { controller: "refresh-on-visible" }) { turbo_stream_from @client, :appointments }
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
      render_install_invite unless @app_installed
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
        span(class: ITEM_DURATION_CLASS) { ::Service::Duration.compact_label(appointment.service.duration_minutes) }
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
    Appointment::Labels.day_label(appointment.starts_at.to_date)
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

  def render_install_invite
    render Components::InstallInvite.for_client(
      name: @tenant.name, icon: @branding.invite_icon, initial: @tenant.initial,
      standalone_path: client_app_installation_path
    )
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
