class Components::Owner::Header < Components::Base
  AGENDA_LABEL = "Agenda".freeze
  SERVICES_LABEL = "Serviços".freeze
  WORKING_HOURS_LABEL = "Horários".freeze
  CLIENTS_LABEL = "Clientes".freeze
  SETTINGS_LABEL = "Configurações".freeze
  SIGN_OUT_LABEL = "Sair".freeze
  PANEL_SUBTITLE = "Painel".freeze

  TAB_CLASS = "inline-flex h-16 items-center px-3.5 text-[14px] leading-[normal]".freeze
  TAB_CURRENT_CLASS = "-mb-px border-b-[3px] border-brand-accent font-extrabold text-brand-accent".freeze
  TAB_RESTING_CLASS = "font-bold text-ink-muted hover:text-ink".freeze

  PILL_CLASS = "inline-flex min-h-10 items-center gap-2 rounded-[10px] border px-3.5 text-[14px] leading-[normal] font-bold".freeze
  PILL_CURRENT_CLASS = "border-brand-accent text-brand-accent".freeze
  PILL_RESTING_CLASS = "border-line text-ink".freeze

  def initialize(tenant:, branding:, current_section:, subtitle: PANEL_SUBTITLE)
    @tenant = tenant
    @branding = branding
    @current_section = current_section
    @subtitle = subtitle
  end

  def view_template
    header(class: "sticky top-0 z-20 border-b border-line bg-surface/90 backdrop-blur", data: { controller: "theme" }) do
      render_desktop_band
      render_mobile_bar
    end
  end

  private

  def render_desktop_band
    div(class: "hidden h-16 items-center gap-6 bg-surface px-10 lg:flex", data: { owner_band: true }) do
      render_band_identity
      div(class: "h-7 w-px flex-none bg-line")
      nav(class: "flex grow") { nav_items.each { |label, href, current| render_tab(label, href, current) } }
      render Components::ThemeToggle.new(hidden_on_phone: false)
      render_settings_pill
    end
  end

  def render_band_identity
    a(href: owner_appointments_path, class: "flex min-w-0 items-center gap-3 font-extrabold text-ink") do
      render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :header)
      span(class: "truncate text-[15px] leading-[normal] tracking-[-0.01em]") { @tenant.name }
    end
  end

  def render_tab(label, href, current)
    a(href: href, aria_current: current ? "page" : nil,
      class: "#{TAB_CLASS} #{current ? TAB_CURRENT_CLASS : TAB_RESTING_CLASS}") { label }
  end

  def render_settings_pill
    current = @current_section == :settings
    a(href: owner_settings_path, aria_current: current ? "page" : nil,
      class: "#{PILL_CLASS} #{current ? PILL_CURRENT_CLASS : PILL_RESTING_CLASS}") do
      render_gear(current)
      plain SETTINGS_LABEL
    end
  end

  def render_gear(current)
    render Components::Icon.new(:settings, class: "h-[17px] w-[17px] flex-none #{current ? "text-brand-accent" : "text-ink-muted"}")
  end

  def render_mobile_bar
    div(class: "flex items-center gap-3 py-3.5 lg:hidden #{content_width}") do
      render_mobile_identity
      render Components::Owner::Menu.new(items: menu_items)
    end
  end

  def render_mobile_identity
    a(href: owner_appointments_path, aria_current: @current_section == :agenda ? "page" : nil,
      class: "flex min-h-11 min-w-0 grow items-center gap-3 font-extrabold text-ink") do
      render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :header)
      span(class: "grid min-w-0 gap-px leading-[normal]") do
        span(class: "truncate text-[14px] tracking-[-0.01em]") { @tenant.name }
        span(class: "min-w-0 truncate text-[11px] font-normal text-ink-muted", data: { panel_subtitle: true }) { @subtitle }
      end
    end
  end

  def content_width = @current_section == :agenda ? Components::Owner::Panel::CONTENT_WIDE : Components::Owner::Panel::CONTENT

  def nav_items
    [
      [ AGENDA_LABEL, owner_appointments_path, @current_section == :agenda ],
      [ SERVICES_LABEL, owner_services_path, @current_section == :services ],
      [ WORKING_HOURS_LABEL, edit_owner_working_hours_path, @current_section == :working_hours ],
      [ CLIENTS_LABEL, owner_clients_path, @current_section == :clients ]
    ]
  end

  def menu_items
    [
      [ CLIENTS_LABEL, owner_clients_path, @current_section == :clients, :users ],
      [ SETTINGS_LABEL, owner_settings_path, @current_section == :settings, :settings ]
    ]
  end
end
