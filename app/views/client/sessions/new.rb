class Views::Client::Sessions::New < Views::Base
  BACK_LABEL = "Voltar".freeze
  TITLE = "Entre para agendar".freeze
  SUBTITLE = "Entre para marcar e acompanhar seus horários na %s.".freeze
  GOOGLE_LABEL = "Continuar com o Google".freeze
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
  GOOGLE_CLASS = "flex min-h-[44px] w-full items-center justify-center gap-2.5 rounded-[10px] border border-[#747775] bg-white px-4 font-[Roboto,_system-ui,_sans-serif] text-[14px] font-medium text-[#1f1f1f]".freeze
  GOOGLE_ICON_CLASS = "h-[18px] w-[18px] flex-none".freeze
  GUEST_CLASS = "flex min-h-[44px] w-full items-center justify-center rounded-[10px] bg-surface text-[14px] font-bold text-ink-muted".freeze
  NOTE_CLASS = "text-center text-[12px] leading-[1.5] text-ink-muted".freeze

  def initialize(tenant:, branding:, service:)
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
      a(href: google_sign_in_href, class: GOOGLE_CLASS, data: { turbo: false, google_button: true }) do
        render_google_icon
        plain GOOGLE_LABEL
      end
      a(href: new_client_service_booking_path(@service), class: GUEST_CLASS, data: { guest_button: true }) { GUEST_LABEL }
      p(class: NOTE_CLASS) { NOTE }
    end
  end

  def google_sign_in_href
    google_entry_url(host: Tenant::PLATFORM_HOST, tenant: @tenant.subdomain, service: @service.id)
  end

  def render_google_icon
    svg(viewBox: "0 0 48 48", class: GOOGLE_ICON_CLASS, aria_hidden: "true") do |icon|
      icon.path(fill: "#EA4335",
        d: "M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z")
      icon.path(fill: "#4285F4",
        d: "M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z")
      icon.path(fill: "#FBBC05",
        d: "M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z")
      icon.path(fill: "#34A853",
        d: "M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z")
    end
  end
end
