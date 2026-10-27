class Views::Owner::Services::Index < Views::Base
  TITLE = "O que eu faço".freeze
  SUBTITLE = "Ativos aparecem na sua página. Desativados ficam guardados com o histórico.".freeze
  DISABLED_LABEL = "Desativado".freeze
  HIDDEN_PRICE_LABEL = "Preço oculto".freeze
  EMPTY_TITLE = "Nenhum serviço cadastrado".freeze
  EMPTY_BODY = "Cadastre o primeiro serviço que você oferece para montar seu catálogo.".freeze
  NEW_LABEL = "Novo".freeze
  NEW_SUFFIX = " serviço".freeze
  NEW_ACCESSIBLE_LABEL = "Novo serviço".freeze
  FIRST_LABEL = "Cadastrar primeiro serviço".freeze

  PAGE_CLASS = "#{Components::Owner::Panel::CONTENT} grid gap-6 py-10".freeze
  HEADING_BLOCK_CLASS = "grid grid-cols-[1fr_auto] items-center gap-x-3 gap-y-1 lg:items-end lg:gap-x-4".freeze
  HEADING_CLASS = "text-[22px] font-extrabold tracking-[-0.02em] text-ink lg:text-[28px]".freeze
  SUBTITLE_CLASS = "hidden text-sm text-ink-muted lg:block".freeze
  ACTION_CLASS = "inline-flex min-h-11 flex-none items-center justify-self-start gap-1.5 rounded-[10px] bg-brand-accent px-3.5 text-sm leading-[normal] font-bold text-on-brand-accent hover:opacity-90 lg:gap-2 lg:px-[18px] lg:row-span-2 lg:self-end".freeze
  PLUS_ICON_CLASS = "h-[18px] w-[18px] flex-none".freeze
  LIST_CLASS = "grid max-w-2xl gap-2.5".freeze
  PRICE_CLASS = "flex-none rounded-full bg-brand-soft px-3 py-[7px] text-[13px] leading-[normal] font-extrabold tabular-nums text-brand-soft-ink".freeze
  DISABLED_PRICE_CLASS = "flex-none rounded-full bg-surface-3 px-3 py-[7px] text-[13px] leading-[normal] font-extrabold tabular-nums text-ink-subtle".freeze
  EMPTY_CLASS = "grid max-w-2xl gap-2 rounded-xl border border-line bg-surface p-6".freeze
  EMPTY_TITLE_CLASS = "text-lg font-bold text-ink".freeze
  EMPTY_BODY_CLASS = "text-sm text-ink-muted".freeze

  def initialize(tenant:, branding:, services:, current_section:, subtitle:)
    @tenant = tenant
    @branding = branding
    @services = services
    @current_section = current_section
    @subtitle = subtitle
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding, flash_in_content: true) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section, subtitle: @subtitle)
      render Components::FlashBanner.new(container_class: "#{Components::Owner::Panel::CONTENT} grid gap-2 pt-4")
      main(class: PAGE_CLASS) do
        render Components::Owner::SettingsBackLink.new
        render_heading
        @services.empty? ? render_empty_state : render_catalog
      end
    end
  end

  private

  def render_heading
    div(class: HEADING_BLOCK_CLASS) do
      h1(class: HEADING_CLASS) { TITLE }
      render_new_action if @services.any?
      p(class: SUBTITLE_CLASS) { SUBTITLE }
    end
  end

  def render_empty_state
    div(class: EMPTY_CLASS) do
      h2(class: EMPTY_TITLE_CLASS) { EMPTY_TITLE }
      p(class: EMPTY_BODY_CLASS) { EMPTY_BODY }
      a(href: new_owner_service_path, class: ACTION_CLASS) { FIRST_LABEL }
    end
  end

  def render_new_action
    a(href: new_owner_service_path, class: ACTION_CLASS, aria_label: NEW_ACCESSIBLE_LABEL) do
      render_plus_icon
      plain NEW_LABEL
      span(class: "hidden lg:inline") { NEW_SUFFIX }
    end
  end

  def render_plus_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      aria_hidden: "true", class: PLUS_ICON_CLASS) do |icon|
      icon.path(d: "M12 5v14M5 12h14")
    end
  end

  def render_catalog
    ul(class: LIST_CLASS, data: { catalog: true }) do
      @services.each { |service| render_service(service) }
    end
  end

  def render_service(service)
    render Components::Service::Card.new(
      service: service,
      href: edit_owner_service_path(service),
      badges: badges_for(service),
      description: service.description
    ) do
      span(class: service.active? ? PRICE_CLASS : DISABLED_PRICE_CLASS, data: { price: true }) { price(service) }
    end
  end

  def badges_for(service)
    [
      (Components::Badge.new(text: DISABLED_LABEL, tone: :muted) unless service.active?),
      (Components::Badge.new(text: HIDDEN_PRICE_LABEL, tone: :muted) if service.price_hidden?)
    ].compact
  end

  def price(service) = ::Service::Price.label(service.price_cents)
end
