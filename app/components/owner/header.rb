class Components::Owner::Header < Components::Base
  include Phlex::Rails::Helpers::ButtonTo

  BRAND_LABEL = "Marca".freeze
  SIGN_OUT_LABEL = "Sair".freeze

  def initialize(tenant:, branding:)
    @tenant = tenant
    @branding = branding
  end

  def view_template
    header(class: "sticky top-0 z-20 border-b border-line bg-surface/90 backdrop-blur", data: { controller: "theme" }) do
      div(class: "mx-auto flex h-16 w-full max-w-6xl items-center gap-3 px-6") do
        render_identity
        render_actions
      end
    end
  end

  private

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

  def render_actions
    div(class: "ml-auto flex flex-none items-center gap-3") do
      a(href: edit_owner_branding_path,
        class: "inline-flex min-h-11 items-center rounded-lg bg-brand-accent px-4 text-sm font-bold text-on-brand-accent shadow-sm hover:opacity-90") { BRAND_LABEL }
      render Components::ThemeToggle.new(hidden_on_phone: false)
      render_sign_out
    end
  end

  def render_sign_out
    button_to(SIGN_OUT_LABEL, owner_session_path, method: :delete,
      class: "inline-flex min-h-11 cursor-pointer items-center rounded-lg border border-line bg-surface px-4 text-sm font-semibold text-ink hover:bg-surface-2")
  end
end
