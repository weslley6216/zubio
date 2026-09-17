class Components::Owner::Service::Fields < Components::Base
  include Components::Form::Styles

  NAME_LABEL = "Nome".freeze
  DESCRIPTION_LABEL = "Descrição (opcional)".freeze
  DURATION_LABEL = "Duração (minutos)".freeze
  DURATION_HINT = "Múltiplos de #{Service::DURATION_STEP_MINUTES} minutos, até #{Service::MAX_DURATION_MINUTES.minutes.in_hours.to_i} horas.".freeze
  PRICE_LABEL = "Preço (R$)".freeze
  PRICE_HINT = "Em reais, com vírgula nos centavos: 90,00.".freeze
  DURATION_HINT_ID = "service-duration-hint".freeze
  PRICE_HINT_ID = "service-price-hint".freeze
  DESCRIPTION_ROWS = 3

  def initialize(service:)
    @service = service
  end

  def view_template
    render_name_field
    render_description_field
    render_duration_field
    render_price_field
  end

  private

  def render_name_field
    div(data: { field: "name" }) do
      label(for: "service_name", class: LABEL) { NAME_LABEL }
      input(type: "text", id: "service_name", name: "service[name]", value: @service.name, required: true,
        maxlength: Service::NAME_MAX_LENGTH, class: CONTROL)
      render Components::Form::Errors.new(messages: @service.errors[:name])
    end
  end

  def render_description_field
    div(data: { field: "description" }) do
      label(for: "service_description", class: LABEL) { DESCRIPTION_LABEL }
      textarea(id: "service_description", name: "service[description]", rows: DESCRIPTION_ROWS,
        maxlength: Service::DESCRIPTION_MAX_LENGTH, class: TEXTAREA) { @service.description }
      render Components::Form::Errors.new(messages: @service.errors[:description])
    end
  end

  def render_duration_field
    div(data: { field: "duration_minutes" }) do
      label(for: "service_duration_minutes", class: LABEL) { DURATION_LABEL }
      input(type: "number", id: "service_duration_minutes", name: "service[duration_minutes]", value: @service.duration_minutes,
        required: true, min: Service::MIN_DURATION_MINUTES, max: Service::MAX_DURATION_MINUTES, step: Service::DURATION_STEP_MINUTES,
        aria: { describedby: DURATION_HINT_ID }, class: CONTROL)
      p(id: DURATION_HINT_ID, class: HINT) { DURATION_HINT }
      render Components::Form::Errors.new(messages: @service.errors[:duration_minutes])
    end
  end

  def render_price_field
    div(data: { field: "price" }) do
      label(for: "service_price", class: LABEL) { PRICE_LABEL }
      input(type: "text", id: "service_price", name: "service[price]", value: @service.price, required: true,
        inputmode: "decimal", aria: { describedby: PRICE_HINT_ID }, class: CONTROL)
      p(id: PRICE_HINT_ID, class: HINT) { PRICE_HINT }
      render Components::Form::Errors.new(messages: @service.errors[:price_cents])
    end
  end
end
