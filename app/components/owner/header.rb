class Components::Owner::Header < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  SIGN_OUT_LABEL = "Sair".freeze
  ITEM_CLASS = "inline-flex min-h-11 items-center rounded-lg px-4 text-sm font-bold".freeze
  CURRENT_CLASS = "bg-secondary-accent text-on-secondary-accent".freeze
  RESTING_CLASS = "text-ink-muted hover:bg-surface-2 hover:text-ink".freeze

  def initialize(tenant:, branding:, current_section:)
    @tenant = tenant
    @branding = branding
    @current_section = current_section
  end

  def view_template
    header(class: "sticky top-0 z-20 border-b border-line bg-surface/90 backdrop-blur", data: { controller: "theme" }) do
      div(class: "mx-auto flex h-16 w-full max-w-6xl items-center gap-3 px-6") do
        render_identity
        render_nav
        render_actions
        render_menu
      end
    end
  end

  private

  def sections
    [
      [ :dashboard, "Painel", owner_dashboard_path ],
      [ :branding, "Marca", edit_owner_branding_path ]
    ]
  end

  def render_identity
    a(href: owner_dashboard_path, class: "flex min-h-11 min-w-0 items-center gap-2 font-extrabold tracking-tight text-ink") do
      render_emblem
      span(class: "truncate") { @tenant.name }
    end
  end

  def render_emblem
    logo = @branding.header_logo

    if logo
      img(src: rails_storage_proxy_path(logo), alt: "", class: "h-8 w-8 flex-none rounded-lg object-contain")
    else
      span(class: "grid h-8 w-8 flex-none place-items-center rounded-lg bg-brand-accent text-on-brand-accent") { emblem_initial }
    end
  end

  def emblem_initial = @tenant.name.first.upcase

  def items = sections.map { |key, label, href| [ label, href, key == @current_section ] }

  def render_nav
    nav(class: "ml-auto hidden items-center gap-1 sm:flex") do
      items.each { |label, href, current| render_section(label, href, current) }
    end
  end

  def render_section(label, href, current)
    a(href: href, aria_current: current ? "page" : nil, class: "#{ITEM_CLASS} #{current ? CURRENT_CLASS : RESTING_CLASS}") { label }
  end

  def render_actions
    div(class: "ml-auto flex flex-none items-center gap-3 sm:ml-0") do
      render Components::ThemeToggle.new(hidden_on_phone: true)
      div(class: "hidden sm:block") { render_sign_out }
    end
  end

  def render_sign_out
    button_to(SIGN_OUT_LABEL, owner_session_path, method: :delete,
      class: "inline-flex min-h-11 cursor-pointer items-center rounded-lg border border-line bg-surface px-4 text-sm font-semibold text-ink hover:bg-surface-2")
  end

  def render_menu
    render Components::Menu.new(items: items) { render_sign_out }
  end
end
