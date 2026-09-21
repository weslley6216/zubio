class Components::Owner::BrandQuestion::Logo < Components::Base
  include Components::Form::Styles

  HEADING_ID = "form-heading".freeze
  TITLE = "Tem uma logo?".freeze
  SUBTITLE = "Pode ser a foto que você usa no Instagram.".freeze
  GALLERY_LABEL = "Galeria".freeze
  CAMERA_LABEL = "Câmera".freeze
  REMOVE_LABEL = "Remover a logo".freeze
  MEGABYTE = 1.megabyte

  TITLE_CLASS = "text-xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "mt-1 text-sm text-ink-muted".freeze
  PREVIEW_CLASS = "mt-4 grid justify-items-center gap-2 rounded-xl border border-dashed border-line-strong bg-surface-2 p-6".freeze
  HINT_CLASS = "text-center text-xs leading-snug text-ink-muted".freeze
  ACTIONS_CLASS = "mt-3 grid grid-cols-2 gap-2".freeze
  PICKER_CLASS = "inline-flex h-11 w-full cursor-pointer items-center justify-center rounded-lg border border-line-strong text-sm font-bold text-ink focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-brand-accent".freeze
  REMOVE_CLASS = "mt-3 flex items-center gap-2 text-sm text-ink-muted".freeze

  def initialize(tenant:, branding:, direct_upload_url: nil)
    @tenant = tenant
    @branding = branding
    @direct_upload_url = direct_upload_url
  end

  def view_template
    div(data: root_data) do
      h1(id: HEADING_ID, class: TITLE_CLASS) { TITLE }
      p(class: SUBTITLE_CLASS) { SUBTITLE }
      input(type: "hidden", name: "branding[logo]", data: { "logo-upload-target": "signedId" }) if direct_upload?
      render_preview
      render_actions
      render_remove if attached?
    end
  end

  private

  def direct_upload? = @direct_upload_url.present?

  def root_data
    return { controller: "logo-field" } unless direct_upload?

    { controller: "logo-field logo-upload", logo_upload_url_value: @direct_upload_url }
  end

  def render_preview
    div(class: PREVIEW_CLASS) do
      render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :large)
      span(class: HINT_CLASS, data: { "logo-field-target": "hint" }) { hint }
    end
  end

  def render_actions
    div(class: ACTIONS_CLASS) do
      render_picker(GALLERY_LABEL, {})
      render_picker(CAMERA_LABEL, capture: "environment")
    end
    render Components::Form::Errors.new(messages: @branding.errors[:logo])
  end

  def render_picker(text, extra)
    label(class: PICKER_CLASS) do
      plain text
      input(type: "file", name: field_name, accept: accept, class: "sr-only",
        data: { action: picker_actions }, **extra)
    end
  end

  def field_name = direct_upload? ? nil : "branding[logo]"

  def picker_actions = direct_upload? ? "logo-field#showChosen logo-upload#upload" : "logo-field#showChosen"

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
