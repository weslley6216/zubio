class Views::Client::Establishments::Show < Views::Base
  EMPTY_TITLE = "Nenhum serviço publicado ainda".freeze
  EMPTY_BODY = "Este estabelecimento ainda não publicou serviços para agendamento.".freeze
  SHARE_DESCRIPTION = "Agende seu horário online — %s.".freeze
  TITLE = "Escolha o serviço".freeze
  SUBTITLE = "Depois você escolhe o dia e o horário.".freeze
  OPEN_UNTIL_LABEL = "Aberto até %s".freeze
  CONFIRMATION_LABEL = "Confirmação na hora".freeze

  MY_APPOINTMENTS_LABEL = "Meus horários".freeze

  BAR_CLASS = "bg-brand-600 px-5 pt-7 pb-10 text-on-brand".freeze
  BAR_COLUMN_CLASS = "mx-auto flex w-full max-w-2xl flex-col gap-3.5".freeze
  IDENTITY_ROW_CLASS = "flex items-center gap-3.5".freeze
  NAME_CLASS = "flex-grow text-[21px] leading-[normal] font-extrabold tracking-[-0.02em]".freeze
  BADGES_ROW_CLASS = "flex flex-wrap items-center gap-1.5".freeze
  BADGE_CLASS = "rounded-full bg-on-brand/20 px-3 py-1.5 text-[11px] leading-[normal] font-bold text-on-brand".freeze
  MY_APPOINTMENTS_MOBILE_CLASS = "flex md:hidden flex-none flex-col items-center gap-1 leading-[normal]".freeze
  MY_APPOINTMENTS_DESKTOP_CLASS = "hidden md:flex ml-1.5 flex-none flex-col items-center gap-1 leading-[normal]".freeze
  MY_APPOINTMENTS_ICON_WRAP_CLASS = "relative grid h-11 w-11 place-items-center rounded-full bg-on-brand/18".freeze
  MY_APPOINTMENTS_ICON_CLASS = "h-5 w-5".freeze
  MY_APPOINTMENTS_BADGE_CLASS = "absolute top-[-3px] right-[-3px] min-w-[18px] h-[18px] rounded-full bg-on-brand px-[5px] text-center text-[11px] leading-[18px] font-extrabold text-brand-600 tabular-nums".freeze
  MY_APPOINTMENTS_CAPTION_CLASS = "text-[11px] font-bold".freeze
  LIST_CLASS = "grid gap-2.5".freeze
  SHEET_CLASS = "mx-auto -mt-5 grid w-full max-w-2xl gap-4 rounded-t-3xl bg-canvas px-5 py-6".freeze
  TITLE_BLOCK_CLASS = "grid gap-1".freeze
  TITLE_CLASS = "text-xl leading-[normal] font-extrabold tracking-[-0.02em] text-ink".freeze
  SUBTITLE_CLASS = "text-[13px] leading-[normal] text-ink-muted".freeze
  EMPTY_CLASS = "grid gap-2 rounded-xl border border-line bg-surface p-6".freeze
  EMPTY_TITLE_CLASS = "text-lg font-bold text-ink".freeze
  EMPTY_BODY_CLASS = "text-sm text-ink-muted".freeze
  PRICE_CLASS = "text-[15px] leading-[normal] font-extrabold tabular-nums text-ink".freeze
  UNPRICED_CLASS = "text-xs leading-[normal] font-bold text-ink-muted".freeze

  def initialize(tenant:, branding:, services:, open_until: nil, authenticated: false, my_appointments_count: nil)
    @tenant = tenant
    @branding = branding
    @services = services
    @open_until = open_until
    @authenticated = authenticated
    @my_appointments_count = my_appointments_count
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding, social: social_meta) do
      render_brand_bar
      main(class: SHEET_CLASS) do
        @services.empty? ? render_empty_state : render_catalog
      end
    end
  end

  private

  def render_brand_bar
    header(class: BAR_CLASS) do
      div(class: BAR_COLUMN_CLASS) do
        div(class: IDENTITY_ROW_CLASS) do
          render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :showcase, tone: :translucent)
          h1(class: NAME_CLASS) { @tenant.name }
          render_my_appointments_button(MY_APPOINTMENTS_MOBILE_CLASS)
        end
        div(class: BADGES_ROW_CLASS) do
          span(class: BADGE_CLASS) { OPEN_UNTIL_LABEL % open_until_text } if @open_until
          span(class: BADGE_CLASS) { CONFIRMATION_LABEL }
          render_my_appointments_button(MY_APPOINTMENTS_DESKTOP_CLASS)
        end
      end
    end
  end

  def render_my_appointments_button(visibility_class)
    a(href: my_appointments_href, aria_label: button_aria, data: { my_appointments_button: true }, class: visibility_class) do
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

  def open_until_text
    @open_until.min.zero? ? "#{@open_until.hour}h" : Kernel.format("%dh%02d", @open_until.hour, @open_until.min)
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
    div(class: TITLE_BLOCK_CLASS) do
      h1(class: TITLE_CLASS) { TITLE }
      p(class: SUBTITLE_CLASS) { SUBTITLE }
    end
    ul(class: LIST_CLASS, data: { catalog: true }) do
      @services.each do |service|
        render Components::Service::Card.new(service: service, href: service_href(service), variant: :showcase, description: service.description) do
          render_price(service)
        end
      end
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
end
