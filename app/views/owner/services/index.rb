class Views::Owner::Services::Index < Views::Base
  TITLE = "O que eu faço".freeze
  SUBTITLE = "Ativos aparecem na sua página. Desativados ficam guardados com o histórico.".freeze
  ACTIVE_LABEL = "Ativo".freeze
  DISABLED_LABEL = "Desativado".freeze
  HIDDEN_PRICE_LABEL = "Preço oculto".freeze
  EMPTY_TITLE = "Nenhum serviço cadastrado".freeze
  EMPTY_BODY = "Cadastre o primeiro serviço que você oferece para montar seu catálogo.".freeze
  NEW_LABEL = "Novo".freeze
  NEW_SUFFIX = " serviço".freeze
  NEW_ACCESSIBLE_LABEL = "Novo serviço".freeze
  FIRST_LABEL = "Cadastrar primeiro serviço".freeze
  COLUMN_SERVICE = "Serviço".freeze
  COLUMN_DURATION = "Duração".freeze
  COLUMN_PRICE = "Preço".freeze
  COLUMN_SITUATION = "Situação".freeze

  PAGE_CLASS = "#{Components::Owner::Panel::CONTENT} grid gap-6 py-10 lg:py-8".freeze
  BACK_LINK_CLASS = "lg:hidden".freeze
  HEADING_BLOCK_CLASS = "grid grid-cols-[1fr_auto] items-center gap-x-3 gap-y-1 leading-[normal] lg:items-end lg:gap-x-4".freeze
  HEADING_CLASS = "text-[22px] font-extrabold tracking-[-0.02em] text-ink lg:text-[28px]".freeze
  SUBTITLE_CLASS = "hidden text-[14px] text-ink-muted lg:col-start-1 lg:block".freeze
  ACTION_CLASS = "inline-flex min-h-11 flex-none items-center justify-self-start gap-1.5 rounded-[10px] bg-brand-accent px-3.5 text-sm leading-[normal] font-bold text-on-brand-accent hover:opacity-90 lg:gap-2 lg:px-[18px] lg:row-span-2 lg:self-end".freeze
  PLUS_ICON_CLASS = "h-[18px] w-[18px] flex-none".freeze
  LIST_CLASS = "grid max-w-2xl gap-2.5 lg:hidden".freeze
  PRICE_CLASS = "flex-none rounded-full bg-brand-soft px-3 py-[7px] text-[13px] leading-[normal] font-extrabold tabular-nums text-brand-soft-ink".freeze
  DISABLED_PRICE_CLASS = "flex-none rounded-full bg-surface-3 px-3 py-[7px] text-[13px] leading-[normal] font-extrabold tabular-nums text-ink-subtle".freeze
  EMPTY_CLASS = "grid max-w-2xl gap-2 rounded-xl border border-line bg-surface p-6".freeze
  EMPTY_TITLE_CLASS = "text-lg font-bold text-ink".freeze
  EMPTY_BODY_CLASS = "text-sm text-ink-muted".freeze
  TABLE_CLASS = "hidden overflow-hidden rounded-2xl border border-line bg-surface leading-[normal] lg:block".freeze
  TABLE_GRID = "grid grid-cols-[minmax(0,1fr)_120px_140px_130px_96px] gap-4 px-5".freeze
  TABLE_HEADER_CLASS = "#{TABLE_GRID} border-b border-line py-3".freeze
  TABLE_ROW_CLASS = "#{TABLE_GRID} items-center border-b border-line py-4".freeze
  TABLE_ROW_DISABLED_CLASS = "#{TABLE_ROW_CLASS} bg-surface-2".freeze
  TABLE_HEADER_LABEL_CLASS = "text-[11px] font-bold uppercase tracking-[0.08em] text-ink-muted".freeze
  TABLE_NAME_CELL_CLASS = "flex min-w-0 flex-col gap-[3px]".freeze
  TABLE_NAME_CLASS = "text-[15px] font-bold text-ink".freeze
  TABLE_NAME_DISABLED_CLASS = "text-[15px] font-bold text-ink-muted".freeze
  TABLE_DESCRIPTION_CLASS = "text-[13px] text-ink-muted".freeze
  TABLE_DURATION_CLASS = "flex items-center gap-1.5 text-[14px] font-semibold tabular-nums text-ink-muted".freeze
  TABLE_DURATION_DISABLED_CLASS = "flex items-center gap-1.5 text-[14px] font-semibold tabular-nums text-ink-subtle".freeze
  TABLE_CLOCK_CLASS = "h-3.5 w-3.5 flex-none text-ink-subtle".freeze
  TABLE_PRICE_STACK_CLASS = "flex flex-col gap-0.5".freeze
  TABLE_PRICE_CLASS = "text-[15px] font-extrabold tabular-nums text-ink".freeze
  TABLE_PRICE_DISABLED_CLASS = "text-[15px] font-extrabold tabular-nums text-ink-subtle".freeze
  TABLE_UNPRICED_CLASS = "text-[13px] font-bold text-ink-muted".freeze
  TABLE_UNPRICED_DISABLED_CLASS = "text-[13px] font-bold text-ink-subtle".freeze
  TABLE_HIDDEN_HINT_CLASS = "text-[11px] font-semibold text-ink-subtle".freeze
  STATUS_PILL_CLASS = "rounded-full px-2.5 py-1 text-[11px] font-extrabold whitespace-nowrap".freeze
  TABLE_ACTIVE_PILL_CLASS = "#{STATUS_PILL_CLASS} bg-brand-soft text-brand-soft-ink".freeze
  TABLE_DISABLED_PILL_CLASS = "#{STATUS_PILL_CLASS} bg-surface-3 text-ink-muted".freeze
  TABLE_ACTION_CELL_CLASS = "flex justify-end".freeze
  TABLE_EDIT_CLASS = "grid h-10 w-10 place-items-center rounded-[9px] border border-line bg-surface text-ink-muted hover:bg-surface-2".freeze
  TABLE_PENCIL_CLASS = "h-[17px] w-[17px] flex-none".freeze

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
        div(class: BACK_LINK_CLASS) { render Components::Owner::SettingsBackLink.new }
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
      span do
        plain NEW_LABEL
        span(class: "hidden lg:inline") { NEW_SUFFIX }
      end
    end
  end

  def render_plus_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      aria_hidden: "true", class: PLUS_ICON_CLASS) do |icon|
      icon.path(d: "M12 5v14M5 12h14")
    end
  end

  def render_catalog
    render_table
    render_list
  end

  def render_table
    div(class: TABLE_CLASS, data: { service_table: true }) do
      render_table_header
      @services.each { |service| render_table_row(service) }
    end
  end

  def render_table_header
    div(class: TABLE_HEADER_CLASS) do
      span(class: TABLE_HEADER_LABEL_CLASS) { COLUMN_SERVICE }
      span(class: TABLE_HEADER_LABEL_CLASS) { COLUMN_DURATION }
      span(class: TABLE_HEADER_LABEL_CLASS) { COLUMN_PRICE }
      span(class: TABLE_HEADER_LABEL_CLASS) { COLUMN_SITUATION }
      span
    end
  end

  def render_table_row(service)
    div(class: service.active? ? TABLE_ROW_CLASS : TABLE_ROW_DISABLED_CLASS) do
      render_table_identity(service)
      render_table_duration(service)
      render_table_price(service)
      render_table_status(service)
      render_table_action(service)
    end
  end

  def render_table_identity(service)
    div(class: TABLE_NAME_CELL_CLASS) do
      span(class: service.active? ? TABLE_NAME_CLASS : TABLE_NAME_DISABLED_CLASS) { service.name }
      span(class: TABLE_DESCRIPTION_CLASS) { service.description } if service.description.present?
    end
  end

  def render_table_duration(service)
    span(class: service.active? ? TABLE_DURATION_CLASS : TABLE_DURATION_DISABLED_CLASS) do
      render_table_clock
      plain ::Service::Duration.minutes_label(service.duration_minutes)
    end
  end

  def render_table_clock
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: TABLE_CLOCK_CLASS) do |icon|
      icon.circle(cx: "12", cy: "12", r: "9")
      icon.path(d: "M12 7v5l3 2")
    end
  end

  def render_table_price(service)
    if service.price_cents.present?
      div(class: TABLE_PRICE_STACK_CLASS, data: { table_price: true }) do
        span(class: service.active? ? TABLE_PRICE_CLASS : TABLE_PRICE_DISABLED_CLASS) { price(service) }
        span(class: TABLE_HIDDEN_HINT_CLASS) { HIDDEN_PRICE_LABEL } if service.price_hidden?
      end
    else
      span(class: TABLE_PRICE_CLASS, data: { table_price: true }) do
        span(class: service.active? ? TABLE_UNPRICED_CLASS : TABLE_UNPRICED_DISABLED_CLASS) { price(service) }
      end
    end
  end

  def render_table_status(service)
    div do
      span(class: service.active? ? TABLE_ACTIVE_PILL_CLASS : TABLE_DISABLED_PILL_CLASS, data: { status: true }) do
        service.active? ? ACTIVE_LABEL : DISABLED_LABEL
      end
    end
  end

  def render_table_action(service)
    div(class: TABLE_ACTION_CELL_CLASS) do
      a(href: edit_owner_service_path(service), aria_label: "Editar #{service.name}", class: TABLE_EDIT_CLASS) do
        render_table_pencil
      end
    end
  end

  def render_table_pencil
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: TABLE_PENCIL_CLASS) do |icon|
      icon.path(d: "M12 20h9")
      icon.path(d: "M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z")
    end
  end

  def render_list
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
