class Views::Owner::Clients::Index < Views::Base
  TITLE = "Suas clientes".freeze
  SEARCH_PLACEHOLDER = "Nome ou telefone".freeze
  SEARCH_LABEL = "Buscar cliente por nome ou telefone".freeze
  FOOTER_MOBILE = "Quem agenda pelo seu link entra aqui sozinho. A lista é sua e não aparece para nenhum outro estabelecimento.".freeze
  FOOTER_DESKTOP = "A lista é sua e não aparece para nenhum outro estabelecimento.".freeze

  MAIN_CLASS = "#{Components::Owner::Panel::CONTENT} grid gap-3.5 py-5 sm:gap-6 sm:py-8".freeze
  HEADER_ROW_CLASS = "flex flex-col gap-3.5 sm:flex-row sm:items-end sm:justify-between sm:gap-4".freeze
  HEADING_BLOCK_CLASS = "order-2 flex flex-col gap-1 sm:order-1 sm:flex-grow".freeze
  TITLE_ROW_CLASS = "flex items-baseline gap-2.5 leading-[normal]".freeze
  TITLE_CLASS = "text-[20px] font-extrabold tracking-[-0.02em] text-ink sm:text-[28px]".freeze
  COUNT_CLASS = "text-[13px] font-bold tabular-nums text-ink-muted sm:hidden".freeze
  SUBTITLE_CLASS = "hidden text-[14px] text-ink-muted sm:block".freeze
  SEARCH_FORM_CLASS = "order-1 flex min-h-12 items-center gap-2.5 rounded-[10px] border border-line-strong bg-surface px-3.5 sm:order-2 sm:min-h-11 sm:w-[340px] sm:flex-none".freeze
  SEARCH_ICON_CLASS = "h-[18px] w-[18px] flex-none text-ink-subtle".freeze
  SEARCH_INPUT_CLASS = "min-w-0 flex-grow bg-transparent text-[15px] text-ink placeholder:text-ink-subtle focus:outline-none".freeze
  FOOTER_CLASS = "text-center text-[12px] leading-[normal] text-ink-subtle".freeze

  def initialize(tenant:, branding:, entries:, total:, query:, current_section:, subtitle:)
    @tenant = tenant
    @branding = branding
    @entries = entries
    @total = total
    @query = query
    @current_section = current_section
    @subtitle = subtitle
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding, flash_in_content: true) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section, subtitle: @subtitle)
      render Components::FlashBanner.new(container_class: "#{Components::Owner::Panel::CONTENT} grid gap-2 pt-4")
      main(class: MAIN_CLASS) do
        render_header_row
        render Components::Owner::Clients::Roster.new(entries: @entries, total: @total, tenant: @tenant)
        render_footer
      end
    end
  end

  private

  def render_header_row
    div(class: HEADER_ROW_CLASS) do
      render_heading
      render_search_form
    end
  end

  def render_heading
    div(class: HEADING_BLOCK_CLASS) do
      div(class: TITLE_ROW_CLASS) do
        h1(class: TITLE_CLASS) { TITLE }
        span(class: COUNT_CLASS) { @total.to_s }
      end
      p(class: SUBTITLE_CLASS) { subtitle_text }
    end
  end

  def subtitle_text = "#{@total} #{@total == 1 ? 'pessoa' : 'pessoas'}. Quem agenda pelo seu link entra aqui sozinho."

  def render_search_form
    form(method: :get, action: owner_clients_path, class: SEARCH_FORM_CLASS,
      data: { turbo_frame: Components::Owner::Clients::Roster::FRAME_ID, controller: "clients-filter" }) do
      render_search_icon
      input(type: "text", name: "q", value: @query, placeholder: SEARCH_PLACEHOLDER, aria_label: SEARCH_LABEL, autocomplete: "off",
        class: SEARCH_INPUT_CLASS, data: { action: "input->clients-filter#search" })
    end
  end

  def render_search_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: SEARCH_ICON_CLASS) do |icon|
      icon.circle(cx: "11", cy: "11", r: "7")
      icon.path(d: "m20 20-4-4")
    end
  end

  def render_footer
    p(class: "#{FOOTER_CLASS} sm:hidden") { FOOTER_MOBILE }
    p(class: "#{FOOTER_CLASS} hidden sm:block") { FOOTER_DESKTOP }
  end
end
