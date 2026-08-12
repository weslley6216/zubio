class Views::Owner::Brandings::Edit < Views::Base
  FIELD_CLASS = "mt-1 w-full rounded-md border border-gray-300 px-3 py-2"

  def initialize(tenant:, branding:)
    @tenant = tenant
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: "Marca · Zubio", branding: @branding) do
      div(class: "mx-auto mt-16 w-full max-w-sm") do
        h1(class: "mb-6 text-center text-2xl font-semibold") { "Marca do estabelecimento" }
        form_with(url: owner_branding_path, method: :patch, multipart: true, class: "space-y-4") do |form|
          render_name_field(form)
          render_color_field(form)
          render_logo_field
          render_remove_logo_field if current_logo_attached?
          form.submit "Salvar", class: "w-full rounded-md bg-brand-600 px-4 py-2 font-medium text-on-brand"
        end
      end
    end
  end

  private

  def render_name_field(form)
    div do
      form.label :name, "Nome do estabelecimento", class: "block text-sm font-medium"
      form.text_field :name, name: "tenant[name]", value: @tenant.name, required: true, class: FIELD_CLASS
      render_errors(@tenant.errors[:name])
    end
  end

  def render_color_field(form)
    div(data: { controller: "color-swatch" }) do
      form.label :brand_600, "Cor da marca", class: "block text-sm font-medium"
      div(class: "mt-1 flex items-center gap-2") do
        form.color_field :swatch, name: "brand_600_swatch", value: @branding.brand_600,
          data: { "color-swatch-target": "swatch", action: "input->color-swatch#syncFromSwatch" }
        form.text_field :brand_600, name: "branding[brand_600]", value: @branding.brand_600, required: true,
          class: FIELD_CLASS, data: { "color-swatch-target": "text", action: "input->color-swatch#syncFromText" }
      end
      render_errors(@branding.errors[:brand_600])
    end
  end

  def render_logo_field
    div do
      label(class: "block text-sm font-medium") { "Logotipo" }
      img(src: rails_storage_proxy_path(@branding.logo), class: "mt-2 h-16 w-16 rounded object-contain") if current_logo_attached?
      input(type: "file", name: "branding[logo]", accept: "image/png,image/jpeg,image/webp", class: "mt-1 block w-full text-sm")
      render_errors(@branding.errors[:logo])
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
      input(type: "checkbox", name: "branding[remove_logo]", id: "branding_remove_logo", value: "1", class: "rounded border-gray-300")
      label(for: "branding_remove_logo", class: "text-sm") { "Remover logotipo atual" }
    end
  end

  def render_errors(messages)
    return if messages.empty?

    p(class: "mt-1 text-sm text-red-700") { messages.join(", ") }
  end
end
