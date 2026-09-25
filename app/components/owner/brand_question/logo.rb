class Components::Owner::BrandQuestion::Logo < Components::Base
  include Components::Form::Styles

  HEADING_ID = "form-heading".freeze
  TITLE = "Tem uma logo?".freeze
  SUBTITLE = "Pode ser a foto que você usa no Instagram.".freeze
  GALLERY_LABEL = "Galeria".freeze
  CAMERA_LABEL = "Câmera".freeze
  REMOVE_LABEL = "Remover a logo".freeze
  UPLOAD_TITLE = "Escolher da galeria".freeze
  UPLOAD_SUBTITLE = "Ou tire uma foto agora.".freeze
  NO_LOGO_LABEL = "Sem logo por enquanto".freeze
  NO_LOGO_TEXT = "Usamos a inicial do seu nome em um quadrinho com a sua cor. Dá para trocar depois.".freeze
  MEGABYTE = 1.megabyte
  PREVIEW_ALT = "Prévia da logo escolhida".freeze

  TITLE_CLASS = "text-xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "mt-1 text-sm text-ink-muted".freeze
  PREVIEW_CLASS = "mt-4 grid justify-items-center gap-2 rounded-xl border border-dashed border-line-strong bg-surface-2 p-6".freeze
  HINT_CLASS = "text-center text-xs leading-snug text-ink-muted".freeze
  ACTIONS_CLASS = "mt-3 grid grid-cols-2 gap-2".freeze
  PICKER_CLASS = "inline-flex h-11 w-full cursor-pointer items-center justify-center rounded-lg border border-line-strong text-sm font-bold text-ink focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-brand-accent".freeze
  REMOVE_CLASS = "mt-3 flex items-center gap-2 text-sm text-ink-muted".freeze

  UPLOAD_CLASS = "mt-4 flex flex-col items-center gap-3 rounded-2xl border-2 border-dashed border-line-strong bg-surface px-5 py-7".freeze
  UPLOAD_ICON_WRAPPER_CLASS = "grid h-14 w-14 place-items-center rounded-full bg-brand-soft".freeze
  UPLOAD_ICON_CLASS = "h-6.5 w-6.5 text-brand-600".freeze
  UPLOAD_TITLE_CLASS = "text-base font-extrabold text-ink".freeze
  UPLOAD_SUBTITLE_CLASS = "text-center text-[13px] leading-normal text-ink-muted".freeze
  ONBOARDING_ACTIONS_CLASS = "mt-0.5 flex w-full gap-2".freeze
  PRIMARY_PICKER_CLASS = "inline-flex h-11 w-full cursor-pointer items-center justify-center rounded-lg bg-brand-600 text-sm font-bold text-on-brand focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-brand-accent".freeze
  SECONDARY_PICKER_CLASS = "inline-flex h-11 w-full cursor-pointer items-center justify-center rounded-lg border border-line-strong text-sm font-bold text-ink focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-brand-accent".freeze
  NO_LOGO_CARD_CLASS = "mt-4 grid gap-3 rounded-2xl border border-line bg-surface p-4".freeze
  NO_LOGO_LABEL_CLASS = "text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  NO_LOGO_ROW_CLASS = "flex items-center gap-3".freeze
  NO_LOGO_TEXT_CLASS = "text-[13px] leading-normal text-ink-muted".freeze

  STATE_CLASS = "mt-2 text-center text-xs leading-snug text-ink-muted".freeze
  ONBOARDING_PREVIEW_CLASS = "h-14 w-14 rounded-full object-cover".freeze
  SETTINGS_PREVIEW_CLASS = "h-12 w-12 rounded-xl object-cover".freeze

  def initialize(tenant:, branding:, direct_upload_url: nil, onboarding: false)
    @tenant = tenant
    @branding = branding
    @direct_upload_url = direct_upload_url
    @onboarding = onboarding
  end

  def view_template
    div(data: root_data) do
      h1(id: HEADING_ID, class: TITLE_CLASS) { TITLE }
      p(class: SUBTITLE_CLASS) { SUBTITLE }
      input(type: "hidden", name: "branding[logo]", data: { "logo-target": "signedId" }) if direct_upload?
      if @onboarding
        render_upload_area
        render_no_logo_card unless attached?
      else
        render_preview
        render_actions
        render_remove if attached?
      end
    end
  end

  private

  def direct_upload? = @direct_upload_url.present?

  def root_data
    data = {
      controller: "logo",
      logo_max_bytes_value: Branding::LOGO_MAX_BYTES,
      logo_content_types_value: Branding::LOGO_CONTENT_TYPES.to_json
    }
    data[:logo_url_value] = @direct_upload_url if direct_upload?
    data
  end

  def render_preview
    div(class: PREVIEW_CLASS) do
      div(data: { "logo-target": "placeholder" }) do
        render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :large)
      end
      img(src: "", alt: PREVIEW_ALT, hidden: true, class: SETTINGS_PREVIEW_CLASS, data: { "logo-target": "preview" })
      span(class: HINT_CLASS) { hint }
    end
    p(class: STATE_CLASS, aria_live: "polite", data: { "logo-target": "state" })
  end

  def render_actions
    div(class: ACTIONS_CLASS) do
      render_picker(GALLERY_LABEL, PICKER_CLASS, {})
      render_picker(CAMERA_LABEL, PICKER_CLASS, capture: "environment")
    end
    render Components::Form::Errors.new(messages: @branding.errors[:logo])
  end

  def render_upload_area
    div(class: UPLOAD_CLASS) do
      div(class: UPLOAD_ICON_WRAPPER_CLASS, data: { "logo-target": "placeholder" }) { render_upload_icon }
      img(src: "", alt: PREVIEW_ALT, hidden: true, class: ONBOARDING_PREVIEW_CLASS, data: { "logo-target": "preview" })
      p(class: UPLOAD_TITLE_CLASS) { UPLOAD_TITLE }
      p(class: UPLOAD_SUBTITLE_CLASS) { UPLOAD_SUBTITLE }
      div(class: ONBOARDING_ACTIONS_CLASS) do
        render_picker(GALLERY_LABEL, PRIMARY_PICKER_CLASS, {})
        render_picker(CAMERA_LABEL, SECONDARY_PICKER_CLASS, capture: "environment")
      end
      p(class: HINT_CLASS) { hint }
    end
    p(class: STATE_CLASS, aria_live: "polite", data: { "logo-target": "state" })
    render Components::Form::Errors.new(messages: @branding.errors[:logo])
  end

  def render_upload_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: UPLOAD_ICON_CLASS) do |icon|
      icon.path(d: "M12 16V4")
      icon.path(d: "m8 8 4-4 4 4")
      icon.path(d: "M5 12v7a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-7")
    end
  end

  def render_no_logo_card
    div(class: NO_LOGO_CARD_CLASS, data: { "logo-target": "noLogo" }) do
      span(class: NO_LOGO_LABEL_CLASS) { NO_LOGO_LABEL }
      div(class: NO_LOGO_ROW_CLASS) do
        render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :large)
        p(class: NO_LOGO_TEXT_CLASS) { NO_LOGO_TEXT }
      end
    end
  end

  def render_picker(text, picker_class, extra)
    label(class: picker_class) do
      plain text
      input(type: "file", name: field_name, accept: accept, class: "sr-only",
        data: { action: picker_actions }, **extra)
    end
  end

  def field_name = direct_upload? ? nil : "branding[logo]"

  def picker_actions = "logo#choose"

  def render_remove
    label(class: REMOVE_CLASS) do
      input(type: "hidden", name: "branding[remove_logo]", value: "0")
      input(type: "checkbox", name: "branding[remove_logo]", value: "1", class: CHECKBOX)
      plain REMOVE_LABEL
    end
  end

  def attached? = @branding.logo.attached? && @branding.logo.blob.persisted?

  def accept = Branding::LOGO_CONTENT_TYPES.join(",")

  def hint = "PNG, JPG ou WEBP, até #{Branding::LOGO_MAX_BYTES / MEGABYTE} MB."
end
