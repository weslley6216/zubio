class Components::Owner::Service::Fields < Components::Base
  include Components::Form::Styles

  NAME_LABEL = "Nome".freeze
  DESCRIPTION_LABEL = "Descrição (opcional)".freeze
  DURATION_LABEL = "Duração (minutos)".freeze
  DURATION_HINT = "Múltiplos de #{Service::DURATION_STEP_MINUTES} minutos, até #{Service::MAX_DURATION_MINUTES.minutes.in_hours.to_i} horas.".freeze
  PRICE_LABEL = "Preço (R$, opcional)".freeze
  PRICE_HINT = "Em reais, com vírgula nos centavos: 90,00. Sem preço fixo? Deixe em branco: o cliente vê \"sob consulta\".".freeze
  DURATION_HINT_ID = "service-duration-hint".freeze
  PRICE_HINT_ID = "service-price-hint".freeze
  DESCRIPTION_ROWS = 3

  def initialize(service:, collection: false, onboarding: false)
    @service = service
    @collection = collection
    @onboarding = onboarding
  end

  def view_template
    render_name_field
    render_description_field unless @onboarding
    render_duration_field
    render_price_field
  end

  private

  def render_name_field
    render_field(:name, NAME_LABEL) do |id|
      input(type: "text", id: id, name: field_name(:name), value: @service.name, required: true,
        maxlength: Service::NAME_MAX_LENGTH, class: CONTROL)
    end
  end

  def render_description_field
    render_field(:description, DESCRIPTION_LABEL) do |id|
      textarea(id: id, name: field_name(:description), rows: DESCRIPTION_ROWS,
        maxlength: Service::DESCRIPTION_MAX_LENGTH, class: TEXTAREA) { @service.description }
    end
  end

  def render_duration_field
    render_field(:duration_minutes, DURATION_LABEL, hint: duration_hint, hint_id: DURATION_HINT_ID) do |id, described_by|
      input(type: "number", id: id, name: field_name(:duration_minutes), value: @service.duration_minutes,
        required: true, min: Service::MIN_DURATION_MINUTES, max: Service::MAX_DURATION_MINUTES, step: Service::DURATION_STEP_MINUTES,
        **described_by_attrs(described_by), class: CONTROL)
    end
  end

  def render_price_field
    render_field(:price, PRICE_LABEL, hint: price_hint, hint_id: PRICE_HINT_ID, error_attribute: :price_cents) do |id, described_by|
      input(type: "text", id: id, name: field_name(:price), value: @service.price,
        inputmode: "decimal", **described_by_attrs(described_by), class: CONTROL)
    end
  end

  def duration_hint
    DURATION_HINT unless @onboarding
  end

  def price_hint
    PRICE_HINT unless @onboarding
  end

  def render_field(attribute, label_text, hint: nil, hint_id: nil, error_attribute: attribute)
    div(data: { field: attribute.to_s }) do
      if @collection
        label(class: LABEL) do
          plain label_text
          yield(nil, nil)
        end
        p(class: HINT) { hint } if hint
      else
        field_id = "service_#{attribute}"
        label(for: field_id, class: LABEL) { label_text }
        yield(field_id, hint ? hint_id : nil)
        p(id: hint_id, class: HINT) { hint } if hint
      end
      render Components::Form::Errors.new(messages: @service.errors[error_attribute])
    end
  end

  def described_by_attrs(described_by) = described_by ? { aria: { describedby: described_by } } : {}

  def field_name(attribute) = @collection ? "services[][#{attribute}]" : "service[#{attribute}]"
end
