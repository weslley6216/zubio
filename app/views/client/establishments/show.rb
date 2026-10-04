class Views::Client::Establishments::Show < Views::Base
  EMPTY_TITLE = "Nenhum serviço publicado ainda".freeze
  EMPTY_BODY = "Este estabelecimento ainda não publicou serviços para agendamento.".freeze
  OWNER_LINK_LABEL = "É o dono deste estabelecimento? Entrar".freeze

  BAR_CLASS = "bg-brand-600 px-6 pb-8 pt-6 text-on-brand".freeze
  BAR_INNER_CLASS = "mx-auto flex w-full max-w-2xl items-center gap-3".freeze
  NAME_CLASS = "text-2xl font-extrabold tracking-tight".freeze
  LIST_CLASS = "grid gap-3".freeze
  MAIN_CLASS = "mx-auto grid w-full max-w-2xl gap-3 px-6 py-8".freeze
  EMPTY_CLASS = "grid gap-2 rounded-xl border border-line bg-surface p-6".freeze
  EMPTY_TITLE_CLASS = "text-lg font-bold text-ink".freeze
  EMPTY_BODY_CLASS = "text-sm text-ink-muted".freeze
  FOOTER_CLASS = "mx-auto w-full max-w-2xl px-6 pb-8".freeze
  OWNER_LINK_CLASS = "text-xs text-ink-subtle hover:text-ink-muted".freeze
  PRICE_CLASS = "ml-auto flex-none text-sm font-bold tabular-nums text-ink".freeze
  UNPRICED_CLASS = "ml-auto flex-none text-sm font-medium text-ink-muted".freeze

  def initialize(tenant:, branding:, services:)
    @tenant = tenant
    @branding = branding
    @services = services
  end

  def view_template
    render Views::Layouts::Application.new(title: @tenant.name, branding: @branding) do
      render_brand_bar
      main(class: MAIN_CLASS) do
        @services.empty? ? render_empty_state : render_catalog
      end
      render_owner_link
    end
  end

  private

  def render_brand_bar
    header(class: BAR_CLASS) do
      div(class: BAR_INNER_CLASS) do
        render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :large)
        h1(class: NAME_CLASS) { @tenant.name }
      end
    end
  end

  def render_catalog
    ul(class: LIST_CLASS, data: { catalog: true }) do
      @services.each do |service|
        render Components::Service::Card.new(service: service, href: new_client_service_booking_path(service)) do
          render_price(service)
        end
      end
    end
  end

  def render_price(service)
    cents = service.public_price_cents
    span(class: cents ? PRICE_CLASS : UNPRICED_CLASS) { ::Service::Price.label(cents) }
  end

  def render_empty_state
    div(class: EMPTY_CLASS) do
      h2(class: EMPTY_TITLE_CLASS) { EMPTY_TITLE }
      p(class: EMPTY_BODY_CLASS) { EMPTY_BODY }
    end
  end

  def render_owner_link
    footer(class: FOOTER_CLASS) do
      a(href: new_owner_session_path, class: OWNER_LINK_CLASS) { OWNER_LINK_LABEL }
    end
  end
end
