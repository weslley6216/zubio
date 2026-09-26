class Views::Owner::Settings::Show < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  TITLE = Components::Owner::Header::SETTINGS_LABEL
  BRAND_GROUP = "Minha marca".freeze
  SERVICE_GROUP = "Atendimento".freeze
  ACCOUNT_GROUP = "Conta".freeze
  NAME_LABEL = "Nome".freeze
  LOGO_LABEL = "Logo".freeze
  LOGO_INITIAL = "Usando a inicial".freeze
  LOGO_UPLOADED = "Logo enviada".freeze
  COLORS_LABEL = "Cores".freeze
  SECONDARY_PREFIX = "apoio".freeze
  ADDRESS_LABEL = "Endereço do link".freeze
  SERVICES_LABEL = "Serviços".freeze
  NO_SERVICES = "Nenhum cadastrado".freeze
  WORKING_HOURS_LABEL = "Horários da semana".freeze
  REGISTERED = { one: "cadastrado", other: "cadastrados" }.freeze
  DISABLED = { one: "desativado", other: "desativados" }.freeze
  CHEVRON_PATH = "m9 6 6 6-6 6".freeze

  PAGE_CLASS = "mx-auto grid w-full max-w-6xl gap-6 px-6 py-10".freeze
  HEADING_CLASS = "text-3xl font-extrabold tracking-tight text-ink".freeze
  GROUP_CLASS = "grid max-w-2xl gap-2".freeze
  GROUP_LABEL_CLASS = "text-xs font-bold uppercase tracking-widest text-ink-muted".freeze
  LIST_CLASS = "divide-y divide-line overflow-hidden rounded-xl border border-line bg-surface".freeze
  ROW_CLASS = "flex min-h-11 items-center gap-3 px-4 py-3.5".freeze
  LINK_ROW_CLASS = "#{ROW_CLASS} hover:bg-surface-2".freeze
  SIGN_OUT_CLASS = "#{ROW_CLASS} w-full cursor-pointer text-left text-sm font-bold text-ink hover:bg-surface-2".freeze
  ROW_TEXT_CLASS = "grid min-w-0 flex-1 gap-0.5".freeze
  ROW_LABEL_CLASS = "text-sm font-bold text-ink".freeze
  ROW_SUMMARY_CLASS = "truncate text-xs text-ink-muted".freeze
  CHIPS_CLASS = "flex flex-none gap-1".freeze
  CHEVRON_CLASS = "h-4 w-4 flex-none text-ink-subtle".freeze

  def initialize(tenant:, branding:, service_counts:, working_hours_summary:, current_section:)
    @tenant = tenant
    @branding = branding
    @service_counts = service_counts
    @working_hours_summary = working_hours_summary
    @current_section = current_section
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section)
      main(class: PAGE_CLASS) do
        h1(class: HEADING_CLASS) { TITLE }
        render_brand_group
        render_service_group
        render_account_group
      end
    end
  end

  private

  def render_brand_group
    render_group("brand-group", BRAND_GROUP) do
      render_link_row("name", NAME_LABEL, @tenant.name, edit_owner_brand_name_path)
      render_link_row("logo", LOGO_LABEL, logo_summary, edit_owner_brand_logo_path) do
        render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :small)
      end
      render_link_row("colors", COLORS_LABEL, colors_summary, edit_owner_brand_colors_path) { render_chips }
      render_row("address", ADDRESS_LABEL, @tenant.canonical_host)
    end
  end

  def render_service_group
    render_group("service-group", SERVICE_GROUP) do
      render_link_row("services", SERVICES_LABEL, services_summary, owner_services_path)
      render_link_row("working_hours", WORKING_HOURS_LABEL, @working_hours_summary, edit_owner_working_hours_path)
    end
  end

  def render_account_group
    render_group("account-group", ACCOUNT_GROUP) do
      li(data: { setting: "sign-out" }) do
        button_to(Components::Owner::Header::SIGN_OUT_LABEL, owner_session_path, method: :delete, class: SIGN_OUT_CLASS)
      end
    end
  end

  def render_group(id, label, &rows)
    section(aria_labelledby: id, class: GROUP_CLASS) do
      h2(id: id, class: GROUP_LABEL_CLASS) { label }
      ul(class: LIST_CLASS, &rows)
    end
  end

  def render_link_row(key, label, summary, href)
    li(data: { setting: key }) do
      a(href: href, class: LINK_ROW_CLASS) do
        render_row_text(label, summary)
        yield if block_given?
        render_chevron
      end
    end
  end

  def render_row(key, label, summary)
    li(data: { setting: key }) do
      div(class: ROW_CLASS) { render_row_text(label, summary) }
    end
  end

  def render_row_text(label, summary)
    span(class: ROW_TEXT_CLASS) do
      span(class: ROW_LABEL_CLASS) { label }
      span(class: ROW_SUMMARY_CLASS, data: { summary: true }) { summary }
    end
  end

  def render_chips
    span(class: CHIPS_CLASS) do
      render Components::ColorChip.new(attribute: :brand_600, size: :large)
      render Components::ColorChip.new(attribute: :brand_secondary_600, size: :large) if secondary?
    end
  end

  def render_chevron
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: CHEVRON_CLASS) { |icon| icon.path(d: CHEVRON_PATH) }
  end

  def logo_summary = @tenant.branded? ? LOGO_UPLOADED : LOGO_INITIAL

  def secondary? = @branding.brand_secondary_600.present?

  def colors_summary
    secondary = "#{SECONDARY_PREFIX} #{@branding.brand_secondary_600.upcase}" if secondary?

    [ @branding.brand_600.upcase, secondary ].compact.join(" · ")
  end

  def services_summary
    total = @service_counts.values.sum
    return NO_SERVICES if total.zero?

    inactive = @service_counts.fetch(:inactive)

    [ counted(total, REGISTERED), (counted(inactive, DISABLED) if inactive.positive?) ].compact.join(", ")
  end

  def counted(amount, words) = "#{amount} #{amount == 1 ? words.fetch(:one) : words.fetch(:other)}"
end
