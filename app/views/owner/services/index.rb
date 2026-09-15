class Views::Owner::Services::Index < Views::Base
  TITLE = "Serviços".freeze
  SUBTITLE = "O que seu estabelecimento oferece.".freeze
  DISABLED_LABEL = "Desativado".freeze
  EMPTY_TITLE = "Nenhum serviço cadastrado".freeze
  EMPTY_BODY = "Cadastre o primeiro serviço que você oferece para montar seu catálogo.".freeze
  NEW_LABEL = "Novo serviço".freeze
  FIRST_LABEL = "Cadastrar primeiro serviço".freeze

  PAGE_CLASS = "mx-auto grid w-full max-w-6xl gap-6 px-6 py-10".freeze
  HEADING_ROW_CLASS = "flex max-w-2xl flex-wrap items-end justify-between gap-4".freeze
  HEADING_CLASS = "text-3xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "text-lg text-ink-muted".freeze
  ACTION_CLASS = "inline-flex min-h-11 items-center justify-self-start rounded-lg bg-brand-accent px-4 text-sm font-bold text-on-brand-accent hover:opacity-90".freeze
  LIST_CLASS = "grid max-w-2xl gap-3".freeze
  CARD_CLASS = "relative flex items-center gap-3 rounded-xl border border-line bg-surface px-4 py-3.5 hover:bg-surface-2".freeze
  NAME_ROW_CLASS = "flex flex-wrap items-center gap-2".freeze
  NAME_CLASS = "text-sm font-bold text-ink after:absolute after:inset-0 after:rounded-xl".freeze
  DESCRIPTION_CLASS = "text-xs text-ink-muted".freeze
  DURATION_CLASS = "text-xs tabular-nums text-ink-muted".freeze
  PRICE_CLASS = "ml-auto flex-none rounded-full bg-surface-3 px-2.5 py-1.5 text-xs font-bold tabular-nums text-ink".freeze
  EMPTY_CLASS = "grid max-w-2xl gap-2 rounded-xl border border-line bg-surface p-6".freeze
  EMPTY_TITLE_CLASS = "text-lg font-bold text-ink".freeze
  EMPTY_BODY_CLASS = "text-sm text-ink-muted".freeze

  def initialize(tenant:, branding:, services:, current_section:)
    @tenant = tenant
    @branding = branding
    @services = services
    @current_section = current_section
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section)
      main(class: PAGE_CLASS) do
        render_heading
        @services.empty? ? render_empty_state : render_catalog
      end
    end
  end

  private

  def render_heading
    div(class: HEADING_ROW_CLASS) do
      div(class: "grid gap-2") do
        h1(class: HEADING_CLASS) { TITLE }
        p(class: SUBTITLE_CLASS) { SUBTITLE }
      end
      render_new_action(NEW_LABEL) if @services.any?
    end
  end

  def render_empty_state
    div(class: EMPTY_CLASS) do
      h2(class: EMPTY_TITLE_CLASS) { EMPTY_TITLE }
      p(class: EMPTY_BODY_CLASS) { EMPTY_BODY }
      render_new_action(FIRST_LABEL)
    end
  end

  def render_new_action(label)
    a(href: new_owner_service_path, class: ACTION_CLASS) { label }
  end

  def render_catalog
    ul(class: LIST_CLASS, data: { catalog: true }) do
      @services.each { |service| render_service(service) }
    end
  end

  def render_service(service)
    li(class: CARD_CLASS) do
      div(class: "grid min-w-0 gap-0.5") do
        render_name(service)
        span(class: DESCRIPTION_CLASS, data: { description: true }) { service.description } if service.description.present?
        span(class: DURATION_CLASS) { duration(service) }
      end
      span(class: PRICE_CLASS) { price(service) }
    end
  end

  def render_name(service)
    div(class: NAME_ROW_CLASS) do
      a(href: edit_owner_service_path(service), class: NAME_CLASS) { service.name }
      render Components::Badge.new(text: DISABLED_LABEL, tone: :muted) unless service.active?
    end
  end

  def duration(service) = "#{service.duration_minutes} min"

  def price(service) = Service::Price.new(service.price_cents).with_currency
end
