class Views::Owner::Dashboard::Show < Views::Base
  SETUP_BADGE = "Comece por aqui".freeze
  SETUP_TITLE = "Configure a marca do seu estabelecimento".freeze
  SETUP_BODY = "Envie o logotipo e escolha a cor que vão pintar este painel, o aplicativo e a página do seu estabelecimento.".freeze
  MANAGE_TITLE = "Marca do estabelecimento".freeze
  MANAGE_BODY = "Ajuste o logotipo e a cor sempre que quiser.".freeze

  def initialize(tenant:, branding:, owner:)
    @tenant = tenant
    @branding = branding
    @owner = owner
  end

  def view_template
    render Views::Layouts::Application.new(title: "Painel · #{@tenant.name}", branding: @branding) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding)
      div(class: "mx-auto grid w-full max-w-6xl gap-6 px-6 py-10") do
        render_greeting
        render_brand_card
      end
    end
  end

  private

  def render_greeting
    div(class: "grid gap-2") do
      h1(class: "text-3xl font-extrabold tracking-tight text-ink") { "Olá, #{owner_first_name}" }
      p(class: "text-lg text-ink-muted") { "Este é o painel de #{@tenant.name}." }
    end
  end

  def owner_first_name = @owner.name.split.first

  def render_brand_card
    branded = @tenant.branded?

    a(href: edit_owner_branding_path,
      class: "grid max-w-xl gap-2 rounded-xl border border-line bg-surface p-6 hover:bg-surface-2") do
      render_setup_badge unless branded
      h2(class: "text-lg font-bold text-ink") { branded ? MANAGE_TITLE : SETUP_TITLE }
      p(class: "text-sm text-ink-muted") { branded ? MANAGE_BODY : SETUP_BODY }
    end
  end

  def render_setup_badge
    span(class: "justify-self-start rounded-full bg-brand-accent px-3 py-1 text-xs font-bold uppercase tracking-wide text-on-brand-accent") { SETUP_BADGE }
  end
end
