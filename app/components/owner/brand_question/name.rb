class Components::Owner::BrandQuestion::Name < Components::Base
  include Components::Form::Styles

  HEADING_ID = "form-heading".freeze
  TITLE = "Qual é o nome da sua marca?".freeze
  SUBTITLE = "É o nome que seus clientes vão ver na página de agendamento.".freeze
  NAME_LABEL = "Nome da marca".freeze
  COUNTER_SUFFIX = "de #{Tenant::NAME_MAX_LENGTH} caracteres".freeze
  ADDRESS_LABEL = "Seu endereço fica assim".freeze

  TITLE_CLASS = "text-xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "mt-1 text-sm text-ink-muted".freeze
  FIELD_CLASS = "mt-4".freeze
  COUNTER_CLASS = "mt-1 text-xs text-ink-muted".freeze
  ADDRESS_CARD_CLASS = "mt-4 grid gap-2 rounded-xl border border-line bg-surface-2 p-3".freeze
  ADDRESS_LABEL_CLASS = "text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  ADDRESS_ROW_CLASS = "flex items-center gap-3".freeze
  ADDRESS_TEXT_CLASS = "grid min-w-0".freeze
  ADDRESS_NAME_CLASS = "truncate text-sm font-bold text-ink".freeze
  ADDRESS_HOST_CLASS = "truncate text-xs text-ink-muted".freeze

  def initialize(tenant:, branding:, deriving: false)
    @tenant = tenant
    @branding = branding
    @deriving = deriving
  end

  def view_template
    div(data: root_data) do
      h1(id: HEADING_ID, class: TITLE_CLASS) { TITLE }
      p(class: SUBTITLE_CLASS) { SUBTITLE }
      render_field
      @deriving ? render_derived_address : render_address
    end
  end

  private

  def root_data
    return { controller: "name-counter" } unless @deriving

    { controller: "name-counter brand-address", brand_address_suffix_value: Tenant::PLATFORM_HOST,
      brand_address_max_length_value: Tenant::SUBDOMAIN_LENGTH.max }
  end

  def render_field
    div(class: FIELD_CLASS) do
      label(for: "tenant_name", class: "sr-only") { NAME_LABEL }
      input(type: "text", id: "tenant_name", name: "tenant[name]", value: @tenant.name, required: true,
        maxlength: Tenant::NAME_MAX_LENGTH, class: CONTROL, data: field_data)
      p(class: COUNTER_CLASS, data: { "name-counter-target": "readout", max: Tenant::NAME_MAX_LENGTH }) { counter_text }
      render Components::Form::Errors.new(messages: @tenant.errors[:name])
    end
  end

  def field_data
    return { "name-counter-target": "field", action: "input->name-counter#count" } unless @deriving

    { "name-counter-target": "field", "brand-address-target": "name",
      action: "input->name-counter#count input->brand-address#render" }
  end

  def render_address
    div(class: ADDRESS_CARD_CLASS) do
      span(class: ADDRESS_LABEL_CLASS) { ADDRESS_LABEL }
      div(class: ADDRESS_ROW_CLASS) do
        render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :medium)
        div(class: ADDRESS_TEXT_CLASS) do
          span(class: ADDRESS_NAME_CLASS) { @tenant.name }
          span(class: ADDRESS_HOST_CLASS) { @tenant.canonical_host }
        end
      end
    end
  end

  def render_derived_address
    div(class: ADDRESS_CARD_CLASS) do
      span(class: ADDRESS_LABEL_CLASS) { ADDRESS_LABEL }
      div(class: ADDRESS_ROW_CLASS) do
        div(class: ADDRESS_TEXT_CLASS) do
          span(class: ADDRESS_HOST_CLASS, data: { "brand-address-target": "address" }) { Tenant::PLATFORM_HOST }
        end
      end
    end
  end

  def counter_text = "#{@tenant.name.to_s.length} #{COUNTER_SUFFIX}"
end
