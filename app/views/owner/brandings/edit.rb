class Views::Owner::Brandings::Edit < Views::Base
  include Components::Form::Styles

  def initialize(tenant:, branding:)
    @tenant = tenant
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Marca · #{@tenant.name}", branding: @branding) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding)
      render Components::Panel.new(title: "Marca do estabelecimento") do
        form_with(url: owner_branding_path, method: :patch, multipart: true, class: "space-y-4") do |form|
          render_name_field(form)
          render_color_field(form)
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

  def render_color_field(form)
    div(data: { controller: "color-swatch" }) do
      form.label :brand_600, "Cor da marca", class: LABEL
      div(class: "mt-1 flex items-center gap-2") do
        form.color_field :swatch, name: "brand_600_swatch", value: @branding.brand_600,
          data: { "color-swatch-target": "swatch", action: "input->color-swatch#syncFromSwatch" }
        form.text_field :brand_600, name: "branding[brand_600]", value: @branding.brand_600, required: true,
          class: CONTROL, data: { "color-swatch-target": "text", action: "input->color-swatch#syncFromText" }
      end
      render Components::Form::Errors.new(messages: @branding.errors[:brand_600])
    end
  end

  def render_logo_field
    div do
      label(class: LABEL) { "Logotipo" }
      img(src: rails_storage_proxy_path(@branding.logo), class: "mt-2 h-16 w-16 rounded object-contain") if current_logo_attached?
      input(type: "file", name: "branding[logo]", accept: "image/png,image/jpeg,image/webp", class: "mt-1 block w-full text-sm")
      render Components::Form::Errors.new(messages: @branding.errors[:logo])
    end
  end

  # A rejected upload leaves an in-memory, unsaved attachment on @branding
  # (logo.attached? is true, but the blob has no id) — signed_id would raise.
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
