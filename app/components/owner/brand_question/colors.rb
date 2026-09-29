class Components::Owner::BrandQuestion::Colors < Components::Base
  include Components::Form::Styles

  HEADING_ID = "form-heading".freeze
  TITLE = "Escolha as cores da sua marca".freeze
  SUBTITLE = "A partir daqui o app inteiro já fica com a sua cara.".freeze
  BRAND_LABEL = "Cor principal".freeze
  BRAND_HINT = "botões e cabeçalho".freeze
  SECONDARY_LABEL = "Cor de apoio".freeze
  SECONDARY_HINT = "detalhes e destaques".freeze
  SECONDARY_OPTIONAL = "Opcional".freeze
  SECONDARY_HELP = "É o caso de quem tem duas cores na fachada, como azul e vermelho na barbearia.".freeze
  PREVIEW_LABEL = "Prévia com as duas cores".freeze
  PREVIEW_PAGE = "Sua página".freeze
  PREVIEW_TODAY = "Hoje".freeze
  PREVIEW_BOOK = "Agendar".freeze
  PREVIEW_SERVICES = "Serviços".freeze

  TITLE_CLASS = "text-[26px] leading-[1.2] font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "mt-1 text-sm text-ink-muted".freeze
  GROUP_CLASS = "mt-4 grid gap-4".freeze
  HELP_CLASS = "mt-1.5 text-xs leading-snug text-ink-subtle".freeze
  PREVIEW_CARD_CLASS = "mt-4 overflow-hidden rounded-2xl border border-line bg-surface".freeze
  PREVIEW_STRIP_CLASS = "#{SECTION_LABEL} border-b border-line bg-surface-2 px-3.5 py-[9px] text-ink-subtle".freeze
  PREVIEW_HEADER_CLASS = "flex items-center gap-3 bg-brand-accent px-3.5 py-3.5 text-on-brand-accent".freeze
  PREVIEW_EMBLEM_CLASS = "grid h-9 w-9 place-items-center rounded-[11px] bg-white/22 text-base font-extrabold".freeze
  PREVIEW_PAGE_CLASS = "flex-grow text-[15px] font-extrabold tracking-[-0.01em]".freeze
  PREVIEW_TODAY_CLASS = "rounded-full bg-secondary-soft px-2.5 py-[5px] text-[11px] font-extrabold text-secondary-soft-ink".freeze
  PREVIEW_ACTIONS_CLASS = "flex gap-2.5 px-3.5 py-3".freeze
  PREVIEW_PRIMARY_CLASS = "grid h-11 flex-grow place-items-center rounded-[10px] bg-brand-600 text-sm font-bold text-on-brand".freeze
  PREVIEW_SECONDARY_CLASS = "grid h-11 place-items-center rounded-[10px] border border-brand-600 px-4 text-sm font-bold text-brand-ink".freeze

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
    div(class: PREVIEW_CARD_CLASS, data: { "color-swatch-target": "preview", preview_brand: @branding.brand_600, preview_secondary: preview_secondary }) do
      div(class: PREVIEW_STRIP_CLASS) { PREVIEW_LABEL }
      div(class: PREVIEW_HEADER_CLASS) do
        span(class: PREVIEW_EMBLEM_CLASS) { "z" }
        span(class: PREVIEW_PAGE_CLASS) { PREVIEW_PAGE }
        span(class: PREVIEW_TODAY_CLASS) { PREVIEW_TODAY }
      end
      div(class: PREVIEW_ACTIONS_CLASS) do
        span(class: PREVIEW_PRIMARY_CLASS) { PREVIEW_BOOK }
        span(class: PREVIEW_SECONDARY_CLASS) { PREVIEW_SERVICES }
      end
    end
  end

  def preview_secondary = @branding.brand_secondary_600.presence || "none"
end
