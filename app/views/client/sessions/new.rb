class Views::Client::Sessions::New < Views::Base
  BACK_LABEL = "Voltar".freeze
  TITLE = "Entre para agendar".freeze
  SUBTITLE = "Entre para marcar e acompanhar seus horários na %s.".freeze
  GUEST_LABEL = "Continuar sem conta".freeze
  NOTE = "Com a conta, seus horários ficam salvos e você desmarca quando quiser.".freeze

  PAGE_CLASS = "mx-auto flex min-h-dvh w-full max-w-[430px] flex-col bg-surface-2 leading-[normal] text-ink".freeze
  HEADER_CLASS = "flex items-center gap-3 bg-brand-600 px-5 py-3.5 text-on-brand".freeze
  BACK_CLASS = "grid h-10 w-10 flex-none place-items-center rounded-[10px] bg-white/18".freeze
  BACK_ICON_CLASS = "h-5 w-5".freeze
  NAME_CLASS = "grow truncate text-[15px] font-extrabold tracking-[-0.01em]".freeze
  MAIN_CLASS = "flex grow flex-col gap-[22px] px-6 pt-12 pb-6".freeze
  IDENTITY_CLASS = "flex flex-col items-center gap-3.5 text-center".freeze
  HEADING_BLOCK_CLASS = "flex flex-col gap-1.5".freeze
  HEADING_CLASS = "text-[24px] leading-[normal] font-extrabold tracking-[-0.02em]".freeze
  SUBTITLE_CLASS = "text-[14px] leading-[1.5] text-pretty text-ink-muted".freeze
  CARD_CLASS = "flex flex-col gap-3 rounded-2xl border border-line bg-surface p-5".freeze
  GUEST_CLASS = "flex min-h-[44px] w-full items-center justify-center rounded-[10px] bg-surface text-[14px] font-bold text-ink-muted".freeze
  NOTE_CLASS = "text-center text-[12px] leading-[1.5] text-ink-muted".freeze

  def initialize(tenant:, branding:, service: nil)
    @tenant = tenant
    @branding = branding
    @service = service
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding) do
      div(class: PAGE_CLASS) do
        render_header
        render_main
      end
    end
  end

  private

  def render_header
    header(class: HEADER_CLASS) do
      a(href: establishment_path, class: BACK_CLASS, aria_label: BACK_LABEL) { render_back_icon }
      h1(class: NAME_CLASS) { @tenant.name }
    end
  end

  def render_back_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BACK_ICON_CLASS) do |icon|
      icon.path(d: "m15 6-6 6 6 6")
    end
  end

  def render_main
    main(class: MAIN_CLASS) do
      render_identity
      render_card
    end
  end

  def render_identity
    div(class: IDENTITY_CLASS) do
      render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :login)
      div(class: HEADING_BLOCK_CLASS) do
        h1(class: HEADING_CLASS) { TITLE }
        span(class: SUBTITLE_CLASS) { SUBTITLE % @tenant.name }
      end
    end
  end

  def render_card
    div(class: CARD_CLASS) do
      render Components::Client::GoogleButton.new(href: google_sign_in_href)
      a(href: new_client_service_booking_path(@service), class: GUEST_CLASS, data: { guest_button: true }) { GUEST_LABEL } if @service
      p(class: NOTE_CLASS) { NOTE }
    end
  end

  def google_sign_in_href
    return google_entry_url(host: Tenant::PLATFORM_HOST, tenant: @tenant.subdomain, service: @service.id) if @service

    google_entry_url(host: Tenant::PLATFORM_HOST, tenant: @tenant.subdomain, appointments: "1")
  end
end
