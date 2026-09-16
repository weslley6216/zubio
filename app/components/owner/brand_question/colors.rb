class Components::Owner::BrandQuestion::Colors < Components::Base
  include Components::Form::Styles

  HEADING_ID = "form-heading".freeze
  TITLE = "Escolha as cores da sua marca".freeze
  SUBTITLE = "A partir daqui o app inteiro já fica com a sua cara.".freeze
  BRAND_LABEL = "Cor principal".freeze
  BRAND_HINT = "Botões e cabeçalho".freeze
  SECONDARY_LABEL = "Cor de apoio".freeze
  SECONDARY_HINT = "Detalhes e destaques".freeze
  SECONDARY_OPTIONAL = "Opcional".freeze
  SECONDARY_HELP = "É o caso de quem tem duas cores na fachada, como azul e vermelho na barbearia.".freeze
  PREVIEW_LABEL = "Prévia com as duas cores".freeze
  PREVIEW_PAGE = "Sua página".freeze
  PREVIEW_TODAY = "Hoje".freeze
  PREVIEW_BOOK = "Agendar".freeze
  PREVIEW_SERVICES = "Serviços".freeze

  TITLE_CLASS = "text-xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "mt-1 text-sm text-ink-muted".freeze
  GROUP_CLASS = "mt-4 grid gap-4".freeze
  HELP_CLASS = "mt-1.5 text-xs leading-snug text-ink-muted".freeze
  PREVIEW_LABEL_CLASS = "text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  PREVIEW_CARD_CLASS = "mt-1.5 grid gap-3 rounded-xl border border-line bg-surface-2 p-3".freeze
  PREVIEW_HEADER_CLASS = "flex items-center justify-between rounded-lg bg-brand-accent px-3 py-2 text-on-brand-accent".freeze
  PREVIEW_TODAY_CLASS = "rounded-full bg-secondary-soft px-2 py-0.5 text-xs font-bold text-secondary-soft-ink".freeze
  PREVIEW_ACTIONS_CLASS = "grid grid-cols-2 gap-2".freeze
  PREVIEW_PRIMARY_CLASS = "h-9 rounded-lg bg-brand-600 text-sm font-bold text-on-brand".freeze
  PREVIEW_SECONDARY_CLASS = "h-9 rounded-lg border border-brand-600 text-sm font-bold text-brand-ink".freeze

  def initialize(tenant:, branding:)
    @tenant = tenant
    @branding = branding
  end

  def view_template
    div(data: { controller: "color-swatch" }) do
      h1(id: HEADING_ID, class: TITLE_CLASS) { TITLE }
      p(class: SUBTITLE_CLASS) { SUBTITLE }
      div(class: GROUP_CLASS) do
        render_group(:brand_600, BRAND_LABEL, BRAND_HINT, @branding.brand_600)
        render_group(:brand_secondary_600, SECONDARY_LABEL, SECONDARY_HINT, @branding.brand_secondary_600, tag: SECONDARY_OPTIONAL, help: SECONDARY_HELP)
      end
      render_preview
    end
  end

  private

  def render_group(attribute, label, hint, selected, tag: nil, help: nil)
    div(data: { action: "change->color-swatch#choose" }) do
      render Components::Form::ColorSwatches.new(label: label, hint: hint, attribute: attribute, selected: selected, fallback: @branding.brand_600, tag: tag)
      p(class: HELP_CLASS) { help } if help
      render Components::Form::Errors.new(messages: @branding.errors[attribute])
    end
  end

  def render_preview
    div(class: "mt-4") do
      span(class: PREVIEW_LABEL_CLASS) { PREVIEW_LABEL }
      div(class: PREVIEW_CARD_CLASS, data: { "color-swatch-target": "preview", preview_brand: @branding.brand_600, preview_secondary: preview_secondary }) do
        div(class: PREVIEW_HEADER_CLASS) do
          span(class: "text-sm font-bold") { PREVIEW_PAGE }
          span(class: PREVIEW_TODAY_CLASS) { PREVIEW_TODAY }
        end
        div(class: PREVIEW_ACTIONS_CLASS) do
          span(class: PREVIEW_PRIMARY_CLASS + " grid place-items-center") { PREVIEW_BOOK }
          span(class: PREVIEW_SECONDARY_CLASS + " grid place-items-center") { PREVIEW_SERVICES }
        end
      end
    end
  end

  def preview_secondary = @branding.brand_secondary_600.presence || "none"
end
