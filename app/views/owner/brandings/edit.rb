class Views::Owner::Brandings::Edit < Views::Base
  include Components::Form::Styles

  BRAND_LABEL = "Cor da marca".freeze
  SECONDARY_LABEL = "Cor secundária".freeze
  SECONDARY_BLANK_LABEL = "Igual à cor da marca".freeze

  def initialize(tenant:, branding:, current_section:)
    @tenant = tenant
    @branding = branding
    @current_section = current_section
  end

  def view_template
    render Views::Layouts::Application.new(title: "Marca · #{@tenant.name}", branding: @branding,
      page_stylesheet: palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section)
      render Components::Panel.new(title: "Marca do estabelecimento") do
        form_with(url: owner_branding_path, method: :patch, multipart: true, class: "space-y-4") do |form|
          render_name_field(form)
          render_brand_color_field
          render_secondary_color_field
          render_logo_field
          render_remove_logo_field if current_logo_attached?
          form.submit "Salvar", class: SUBMIT
        end
      end
    end
  end

  private

  def render_name_field(form)
    div do
      form.label :name, "Nome do estabelecimento", class: LABEL
      form.text_field :name, name: "tenant[name]", value: @tenant.name, required: true, class: CONTROL
      render Components::Form::Errors.new(messages: @tenant.errors[:name])
    end
  end

  def render_brand_color_field
    div do
      render Components::Form::ColorSwatches.new(
        label: BRAND_LABEL,
        name: "branding[brand_600]",
        custom_name: "branding[brand_600_custom]",
        selected: @branding.brand_600
      )
      render Components::Form::Errors.new(messages: @branding.errors[:brand_600])
    end
  end

  def render_secondary_color_field
    div do
      render Components::Form::ColorSwatches.new(
        label: SECONDARY_LABEL,
        name: "branding[brand_secondary_600]",
        custom_name: "branding[brand_secondary_600_custom]",
        selected: @branding.brand_secondary_600,
        blank_label: SECONDARY_BLANK_LABEL
      )
      render Components::Form::Errors.new(messages: @branding.errors[:brand_secondary_600])
    end
  end

  def render_logo_field
    div do
      label(class: LABEL) { "Logotipo" }
      img(src: rails_storage_proxy_path(@branding.header_logo), class: "mt-2 h-16 w-16 rounded object-contain") if current_logo_attached?
      input(type: "file", name: "branding[logo]", accept: "image/png,image/jpeg,image/webp", class: "mt-1 block w-full text-sm")
      render Components::Form::Errors.new(messages: @branding.errors[:logo])
    end
  end

  def current_logo_attached?
    @branding.logo.attached? && @branding.logo.blob.persisted?
  end

  def render_remove_logo_field
    div(class: "mt-2 flex items-center gap-2") do
      input(type: "hidden", name: "branding[remove_logo]", value: "0")
      input(type: "checkbox", name: "branding[remove_logo]", id: "branding_remove_logo", value: "1", class: CHECKBOX)
      label(for: "branding_remove_logo", class: "text-sm") { "Remover logotipo atual" }
    end
  end
end
