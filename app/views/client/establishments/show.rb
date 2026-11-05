class Views::Client::Establishments::Show < Views::Base
  EMPTY_TITLE = "Nenhum serviço publicado ainda".freeze
  EMPTY_BODY = "Este estabelecimento ainda não publicou serviços para agendamento.".freeze
  SHARE_DESCRIPTION = "Agende seu horário online — %s.".freeze
  TITLE = "Escolha o serviço".freeze
  SUBTITLE = "Depois você escolhe o dia e o horário.".freeze

  MY_APPOINTMENTS_LABEL = "Meus horários".freeze

  PAGE_CLASS = "flex min-h-dvh flex-col bg-(--theme-bg) text-(--theme-on-bg)".freeze
  BAR_CLASS = "px-5 pt-6 pb-2".freeze
  IDENTITY_ROW_CLASS = "mx-auto flex w-full max-w-2xl items-center gap-3".freeze
  IDENTITY_TEXT_CLASS = "flex min-w-0 flex-grow flex-col gap-0.5 leading-[normal]".freeze
  NAME_CLASS = "text-[20px] font-extrabold tracking-[-0.02em]".freeze
  HOURS_CLASS = "text-[13px] text-(--theme-on-bg-muted)".freeze
  MY_APPOINTMENTS_CLASS = "flex flex-none flex-col items-center gap-1 leading-[normal]".freeze
  MY_APPOINTMENTS_ICON_WRAP_CLASS = "relative grid h-11 w-11 place-items-center rounded-xl bg-(--theme-bg-tint)".freeze
  MY_APPOINTMENTS_ICON_CLASS = "h-5 w-5".freeze
  MY_APPOINTMENTS_BADGE_CLASS = "absolute top-[-3px] right-[-3px] min-w-[18px] h-[18px] rounded-full bg-(--theme-accent) px-[5px] text-center text-[11px] leading-[18px] font-extrabold text-(--theme-on-accent) tabular-nums".freeze
  MY_APPOINTMENTS_CAPTION_CLASS = "text-[11px] font-bold".freeze
  LIST_CLASS = "grid grid-cols-2 gap-3".freeze
  SHEET_CLASS = "mx-auto grid w-full max-w-2xl gap-3.5 px-5 pt-3.5 pb-5".freeze
  TITLE_BLOCK_CLASS = "grid gap-[3px] pt-2.5".freeze
  TITLE_CLASS = "text-xl leading-[normal] font-extrabold tracking-[-0.02em]".freeze
  SUBTITLE_CLASS = "text-[13px] leading-[normal] text-(--theme-on-bg-muted)".freeze
  EMPTY_CLASS = "grid gap-2 rounded-2xl bg-(--theme-card) p-6 text-(--theme-on-card)".freeze
  EMPTY_TITLE_CLASS = "text-lg font-bold".freeze
  EMPTY_BODY_CLASS = "text-sm text-(--theme-on-card-muted)".freeze
  PRICE_CLASS = "text-[14px] leading-[normal] font-extrabold".freeze
  UNPRICED_CLASS = "text-xs leading-[normal] font-bold text-(--theme-on-card-muted)".freeze
  NOTICE_CLASS = "flex items-start gap-2.5 rounded-2xl bg-(--theme-card) px-3.5 py-3 text-(--theme-on-card) ring-[1.5px] ring-(--theme-danger-on-card) ring-inset".freeze
  NOTICE_ICON_CLASS = "h-[18px] w-[18px] flex-none text-(--theme-danger-on-card)".freeze
  NOTICE_TEXT_CLASS = "text-[13px] leading-[1.5]".freeze

  def initialize(tenant:, branding:, services:, hours: nil, authenticated: false, my_appointments_count: nil, app_installed: false)
    @tenant = tenant
    @branding = branding
    @services = services
    @hours = hours
    @authenticated = authenticated
    @my_appointments_count = my_appointments_count
    @app_installed = app_installed
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding, social: social_meta, flash_in_content: true) do
      div(class: PAGE_CLASS, data: { page: true }) do
        render_brand_bar
        main(class: SHEET_CLASS) do
          @services.empty? ? render_empty_state : render_catalog
          render_install_invite unless @authenticated && @app_installed
        end
      end
    end
  end

  private

  def render_brand_bar
    header(class: BAR_CLASS) do
      div(class: IDENTITY_ROW_CLASS) do
        render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :showcase, tone: :card)
        div(class: IDENTITY_TEXT_CLASS) do
          h1(class: NAME_CLASS) { @tenant.name }
          span(class: HOURS_CLASS, data: { opening_hours: true }) { @hours } if @hours
        end
        render_my_appointments_button
      end
    end
  end

  def render_my_appointments_button
    a(href: my_appointments_href, aria_label: button_aria, data: { my_appointments_button: true }, class: MY_APPOINTMENTS_CLASS) do
      div(class: MY_APPOINTMENTS_ICON_WRAP_CLASS) do
        render_my_appointments_icon
        span(class: MY_APPOINTMENTS_BADGE_CLASS, data: { my_appointments_badge: true }) { @my_appointments_count.to_s } if badge?
      end
      span(class: MY_APPOINTMENTS_CAPTION_CLASS) { MY_APPOINTMENTS_LABEL }
    end
  end

  def render_my_appointments_icon
    render Components::Icon.new(:calendar, class: MY_APPOINTMENTS_ICON_CLASS)
  end

  def badge? = @my_appointments_count.to_i.positive?

  def my_appointments_href = @authenticated ? client_my_appointments_path : new_client_session_path

  def button_aria
    return "Meus agendamentos" unless badge?

    "Meus agendamentos, #{@my_appointments_count} #{@my_appointments_count == 1 ? "próximo" : "próximos"}"
  end

  def social_meta
    Components::SocialMeta.new(
      title: @tenant.name,
      description: SHARE_DESCRIPTION % @tenant.name,
      url: root_url(host: @tenant.canonical_host),
      image_url: share_image_url
    )
  end

  def share_image_url
    variant = @branding.social_image_variant
    rails_storage_proxy_url(variant, host: @tenant.canonical_host) if variant
  end

  def render_catalog
    render_signin_failed_notice if flash[:alert]
    div(class: TITLE_BLOCK_CLASS) do
      h1(class: TITLE_CLASS) { TITLE }
      p(class: SUBTITLE_CLASS) { SUBTITLE }
    end
    ul(class: LIST_CLASS, data: { catalog: true }) do
      @services.each do |service|
        render Components::Service::Card.new(service: service, href: service_href(service), variant: :tile, description: service.description) do
          render_price(service)
        end
      end
    end
  end

  def render_signin_failed_notice
    div(class: NOTICE_CLASS) do
      render Components::Icon.new(:circle_alert, class: NOTICE_ICON_CLASS)
      span(class: NOTICE_TEXT_CLASS) { flash[:alert] }
    end
  end

  def service_href(service)
    @authenticated ? new_client_service_booking_path(service) : new_client_session_path(service_id: service.id)
  end

  def render_price(service)
    cents = service.public_price_cents
    span(class: cents ? PRICE_CLASS : UNPRICED_CLASS) { ::Service::Price.compact_label(cents) }
  end

  def render_empty_state
    div(class: EMPTY_CLASS) do
      h2(class: EMPTY_TITLE_CLASS) { EMPTY_TITLE }
      p(class: EMPTY_BODY_CLASS) { EMPTY_BODY }
    end
  end

  def render_install_invite
    render Components::InstallInvite.for_client(
      name: @tenant.name, icon: @branding.invite_icon, initial: @tenant.initial,
      require_visit: !@authenticated,
      standalone_path: (client_app_installation_path if @authenticated)
    )
  end
end
