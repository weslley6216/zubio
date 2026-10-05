class Views::Owner::Dashboard::Show < Views::Base
  SHARE_LABEL = "Seu link".freeze
  SHARE_HELPER = "Mande esse endereço para suas clientes. É por ele que elas escolhem o horário.".freeze

  def initialize(tenant:, branding:, owner:, current_section:)
    @tenant = tenant
    @branding = branding
    @owner = owner
    @current_section = current_section
  end

  def view_template
    render Views::Layouts::Application.new(title: "Painel · #{@tenant.name}", branding: @branding) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section)
      div(class: "mx-auto grid w-full max-w-6xl gap-6 px-6 py-10") do
        render_greeting
        render_share_link
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

  def render_share_link
    render Components::Owner::ShareLink.new(
      host: @tenant.canonical_host,
      name: @tenant.name,
      label: SHARE_LABEL,
      helper: SHARE_HELPER
    )
  end

  def owner_first_name = @owner.name.split.first
end
