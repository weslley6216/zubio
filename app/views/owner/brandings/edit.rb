class Views::Owner::Brandings::Edit < Views::Base
  include Components::Form::Styles

  HEADING_ID = "brand-heading".freeze
  TITLE = "Sua marca".freeze
  SUBTITLE = "É assim que a cliente vê seu link.".freeze
  NAME_LABEL = "Nome do estabelecimento".freeze
  BRAND_LABEL = "Cor da marca".freeze
  SECONDARY_LABEL = "Cor secundária".freeze
  SECONDARY_LINKED_LABEL = "Igual à marca".freeze
  LOGO_LABEL = "Logotipo".freeze
  LOGO_HINT = "PNG, JPG ou WEBP — fundo transparente ajuda.".freeze
  LOGO_CHANGE_LABEL = "Trocar".freeze
  REMOVE_LOGO_LABEL = "Remover logotipo atual".freeze
  SUBMIT_LABEL = "Salvar minha marca".freeze
  LOGO_CONTENT_TYPES = Branding::LOGO_CONTENT_TYPES.join(",").freeze

  PAGE_CLASS = "mx-auto w-full max-w-md px-3 py-4".freeze
  CARD_CLASS = "rounded-2xl border border-line bg-surface p-4".freeze
  TITLE_CLASS = "text-xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "text-sm text-ink-muted".freeze
  FORM_CLASS = "mt-3 grid grid-cols-1 gap-3.5".freeze
  LOGO_CARD_CLASS = "flex items-center gap-3 rounded-xl border border-line bg-surface-2 p-3".freeze
  LOGO_PREVIEW_CLASS = "h-12 w-12 flex-none rounded-xl object-contain".freeze
  LOGO_INITIAL_CLASS = "grid h-12 w-12 flex-none place-items-center rounded-xl bg-brand-accent font-extrabold text-on-brand-accent".freeze
  LOGO_NAME_CLASS = "block truncate text-sm font-bold text-ink".freeze
  LOGO_HINT_CLASS = "block text-xs leading-snug text-ink-muted".freeze
  LOGO_CHANGE_CLASS = "inline-flex h-11 flex-none cursor-pointer items-center rounded-lg border border-line-strong px-4 text-sm font-bold text-ink focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-brand-accent".freeze
  REMOVE_LOGO_CLASS = "flex items-center gap-2 text-sm text-ink-muted".freeze

  def initialize(tenant:, branding:, current_section:)
    @tenant = tenant
    @branding = branding
    @current_section = current_section
  end

  def view_template
    render Views::Layouts::Application.new(title: "Marca · #{@tenant.name}", branding: @branding,
      page_stylesheet: palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section)
      main(class: PAGE_CLASS) do
        section(aria_labelledby: HEADING_ID, data: { panel: true }, class: CARD_CLASS) do
          render_heading
          render_form
        end
      end
    end
  end

  private

  def render_heading
    h1(id: HEADING_ID, class: TITLE_CLASS) { TITLE }
    p(class: SUBTITLE_CLASS) { SUBTITLE }
  end

  def render_form
    form_with(url: owner_branding_path, method: :patch, multipart: true, class: FORM_CLASS) do |form|
      render_name_field(form)
      render_brand_color_field
      render_secondary_color_field
      render_logo_field
      form.submit SUBMIT_LABEL, class: SUBMIT
    end
  end

  def render_name_field(form)
    div do
      form.label :name, NAME_LABEL, class: LABEL
      form.text_field :name, name: "tenant[name]", value: @tenant.name, required: true, class: CONTROL
      render Components::Form::Errors.new(messages: @tenant.errors[:name])
    end
  end

  def render_brand_color_field
    div do
      render Components::Form::ColorSwatches.new(
        label: BRAND_LABEL,
        attribute: :brand_600,
        selected: @branding.brand_600
      )
      render Components::Form::Errors.new(messages: @branding.errors[:brand_600])
    end
  end

  def render_secondary_color_field
    div do
      render Components::Form::ColorSwatches.new(
        label: SECONDARY_LABEL,
        attribute: :brand_secondary_600,
        selected: @branding.brand_secondary_600,
        fallback: @branding.brand_600,
        linked_label: SECONDARY_LINKED_LABEL
      )
      render Components::Form::Errors.new(messages: @branding.errors[:brand_secondary_600])
    end
  end

  def render_logo_field
    div do
      div(class: LOGO_CARD_CLASS, data: { controller: "logo-field" }) do
        render_logo_preview
        div(class: "min-w-0 flex-1") do
          span(class: LOGO_NAME_CLASS) { LOGO_LABEL }
          span(class: LOGO_HINT_CLASS, data: { "logo-field-target": "hint" }) { LOGO_HINT }
        end
        render_logo_picker
      end
      render Components::Form::Errors.new(messages: @branding.errors[:logo])
      render_remove_logo_field if current_logo_attached?
    end
  end

  def render_logo_preview
    if current_logo_attached?
      img(src: rails_storage_proxy_path(@branding.header_logo), alt: "", class: LOGO_PREVIEW_CLASS)
    else
      span(class: LOGO_INITIAL_CLASS) { @tenant.initial }
    end
  end

  def render_logo_picker
    label(class: LOGO_CHANGE_CLASS) do
      plain LOGO_CHANGE_LABEL
      input(type: "file", name: "branding[logo]", accept: LOGO_CONTENT_TYPES, class: "sr-only",
        data: { action: "logo-field#showChosen" })
    end
  end

  def current_logo_attached?
    @branding.logo.attached? && @branding.logo.blob.persisted?
  end

  def render_remove_logo_field
    label(class: "#{REMOVE_LOGO_CLASS} mt-2") do
      input(type: "hidden", name: "branding[remove_logo]", value: "0")
      input(type: "checkbox", name: "branding[remove_logo]", value: "1", class: CHECKBOX)
      plain REMOVE_LOGO_LABEL
    end
  end
end
