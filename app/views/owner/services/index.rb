class Views::Owner::Services::Index < Views::Base
  include Phlex::Rails::Helpers::NumberToCurrency

  TITLE = "Serviços".freeze
  SUBTITLE = "O que seu estabelecimento oferece.".freeze
  DISABLED_LABEL = "Desativado".freeze
  EMPTY_TITLE = "Nenhum serviço cadastrado".freeze
  EMPTY_BODY = "Cadastre o primeiro serviço que você oferece para montar seu catálogo.".freeze

  PAGE_CLASS = "mx-auto grid w-full max-w-6xl gap-6 px-6 py-10".freeze
  HEADING_CLASS = "text-3xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "text-lg text-ink-muted".freeze
  LIST_CLASS = "grid max-w-2xl gap-3".freeze
  CARD_CLASS = "flex items-center gap-3 rounded-xl border border-line bg-surface px-4 py-3.5".freeze
  NAME_ROW_CLASS = "flex flex-wrap items-center gap-2".freeze
  NAME_CLASS = "text-sm font-bold text-ink".freeze
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
        render_catalog
      end
    end
  end

  private

  def render_heading
    div(class: "grid gap-2") do
      h1(class: HEADING_CLASS) { TITLE }
      p(class: SUBTITLE_CLASS) { SUBTITLE }
    end
  end

  def render_catalog
    ul(class: LIST_CLASS, data: { catalog: true }) do
      @services.each { |service| render_service(service) }
    end
  end

  def render_service(service)
    li(class: CARD_CLASS) do
      div(class: "grid min-w-0 gap-0.5") do
        span(class: NAME_CLASS) { service.name }
        span(class: DESCRIPTION_CLASS) { service.description } if service.description.present?
        span(class: DURATION_CLASS) { duration(service) }
      end
      span(class: PRICE_CLASS) { price(service) }
    end
  end

  def duration(service) = "#{service.duration_minutes} min"

  def price(service)
    number_to_currency(service.price, unit: "R$", separator: ",", delimiter: ".", format: "%u %n")
  end
end
