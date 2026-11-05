class Components::Owner::BrandQuestion::Colors < Components::Base
  include Components::Form::Styles

  HEADING_ID = "form-heading".freeze
  TITLE = "As cores da sua página".freeze
  SUBTITLE = "Escolha o fundo e o destaque. Os cartões e a cor do texto saem sozinhos.".freeze
  BACKGROUND_LABEL = "Fundo".freeze
  BACKGROUND_HINT = "A cor que veste a página".freeze
  ACCENT_LABEL = "Destaque".freeze
  ACCENT_HINT = "Botão principal e o que está selecionado".freeze
  PREVIEW_SERVICE_NAME = "Corte + barba".freeze
  PREVIEW_SERVICE_META = "1h10 · R$ 70".freeze
  PREVIEW_BOOK = "Agendar".freeze
  PREVIEW_CAPTION = "Prévia: fundo, cartão gerado e destaque".freeze

  ROOT_CLASS = "flex flex-col gap-3.5 leading-[normal]".freeze
  HEADING_BLOCK_CLASS = "flex flex-col gap-1.5".freeze
  TITLE_CLASS = "text-[24px] font-extrabold tracking-[-0.02em] text-ink".freeze
  SUBTITLE_CLASS = "text-[14px] leading-[1.5] text-ink-muted".freeze
  GROUP_CARD_CLASS = "rounded-2xl border border-line bg-surface p-4 in-data-panel:rounded-none in-data-panel:border-0 in-data-panel:p-0".freeze
  PREVIEW_CLASS = "flex flex-col gap-3.5".freeze
  PREVIEW_PANEL_CLASS = "flex items-center gap-3 rounded-2xl bg-(--theme-bg) p-3".freeze
  PREVIEW_CARD_CLASS = "flex-grow flex flex-col gap-2 rounded-xl bg-(--theme-card) p-3".freeze
  PREVIEW_NAME_CLASS = "block text-[13px] font-extrabold text-(--theme-on-card)".freeze
  PREVIEW_META_CLASS = "block text-[12px] text-(--theme-on-card-muted)".freeze
  PREVIEW_BOOK_CLASS = "flex min-h-11 flex-none items-center justify-center rounded-[10px] bg-(--theme-accent) px-3.5 text-[13px] font-extrabold text-(--theme-on-accent)".freeze
  PREVIEW_CAPTION_CLASS = "text-center text-[12px] text-ink-muted".freeze

  def initialize(tenant:, branding:)
    @tenant = tenant
    @branding = branding
  end

  def view_template
    div(class: ROOT_CLASS, data: { controller: "color-swatch" }) do
      div(class: HEADING_BLOCK_CLASS) do
        h1(id: HEADING_ID, class: TITLE_CLASS) { TITLE }
        p(class: SUBTITLE_CLASS) { SUBTITLE }
      end
      render_group(:brand_background, BACKGROUND_LABEL, BACKGROUND_HINT, @branding.brand_background, fallback: Branding::Palette::STARTING.fetch(:brand_background))
      render_group(:brand_600, ACCENT_LABEL, ACCENT_HINT, @branding.brand_600, fallback: Branding::Palette::STARTING.fetch(:brand_600))
      render_preview
    end
  end

  private

  def render_group(attribute, label, hint, selected, fallback:)
    div(class: GROUP_CARD_CLASS, data: { action: "change->color-swatch#choose" }) do
      render Components::Form::ColorSwatches.new(label: label, hint: hint, attribute: attribute, selected: selected, fallback: fallback)
      render Components::Form::Errors.new(messages: @branding.errors[attribute])
    end
  end

  def render_preview
    div(class: PREVIEW_CLASS, data: { "color-swatch-target": "preview", preview_bg: preview_bg, preview_accent: @branding.brand_600 }) do
      div(class: PREVIEW_PANEL_CLASS) do
        div(class: PREVIEW_CARD_CLASS) do
          span(class: PREVIEW_NAME_CLASS) { PREVIEW_SERVICE_NAME }
          span(class: PREVIEW_META_CLASS) { PREVIEW_SERVICE_META }
        end
        span(class: PREVIEW_BOOK_CLASS, data: { preview_role: "book" }) { PREVIEW_BOOK }
      end
      p(class: PREVIEW_CAPTION_CLASS) { PREVIEW_CAPTION }
    end
  end

  def preview_bg = @branding.brand_background.presence || "none"
end
