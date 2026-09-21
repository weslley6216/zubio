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

  def initialize(service:, collection: false)
    @service = service
    @collection = collection
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
      if @collection
        label(class: LABEL) do
          plain NAME_LABEL
          input(type: "text", name: field_name(:name), value: @service.name, required: true,
            maxlength: Service::NAME_MAX_LENGTH, class: CONTROL)
        end
      else
        label(for: "service_name", class: LABEL) { NAME_LABEL }
        input(type: "text", id: "service_name", name: field_name(:name), value: @service.name, required: true,
          maxlength: Service::NAME_MAX_LENGTH, class: CONTROL)
      end
      render Components::Form::Errors.new(messages: @service.errors[:name])
    end
  end

  def render_description_field
    div(data: { field: "description" }) do
      if @collection
        label(class: LABEL) do
          plain DESCRIPTION_LABEL
          textarea(name: field_name(:description), rows: DESCRIPTION_ROWS,
            maxlength: Service::DESCRIPTION_MAX_LENGTH, class: TEXTAREA) { @service.description }
        end
      else
        label(for: "service_description", class: LABEL) { DESCRIPTION_LABEL }
        textarea(id: "service_description", name: field_name(:description), rows: DESCRIPTION_ROWS,
          maxlength: Service::DESCRIPTION_MAX_LENGTH, class: TEXTAREA) { @service.description }
      end
      render Components::Form::Errors.new(messages: @service.errors[:description])
    end
  end

  def render_duration_field
    div(data: { field: "duration_minutes" }) do
      if @collection
        label(class: LABEL) do
          plain DURATION_LABEL
          input(type: "number", name: field_name(:duration_minutes), value: @service.duration_minutes,
            required: true, min: Service::MIN_DURATION_MINUTES, max: Service::MAX_DURATION_MINUTES, step: Service::DURATION_STEP_MINUTES,
            class: CONTROL)
        end
        p(class: HINT) { DURATION_HINT }
      else
        label(for: "service_duration_minutes", class: LABEL) { DURATION_LABEL }
        input(type: "number", id: "service_duration_minutes", name: field_name(:duration_minutes), value: @service.duration_minutes,
          required: true, min: Service::MIN_DURATION_MINUTES, max: Service::MAX_DURATION_MINUTES, step: Service::DURATION_STEP_MINUTES,
          aria: { describedby: DURATION_HINT_ID }, class: CONTROL)
        p(id: DURATION_HINT_ID, class: HINT) { DURATION_HINT }
      end
      render Components::Form::Errors.new(messages: @service.errors[:duration_minutes])
    end
  end

  def render_price_field
    div(data: { field: "price" }) do
      if @collection
        label(class: LABEL) do
          plain PRICE_LABEL
          input(type: "text", name: field_name(:price), value: @service.price, required: true,
            inputmode: "decimal", class: CONTROL)
        end
        p(class: HINT) { PRICE_HINT }
      else
        label(for: "service_price", class: LABEL) { PRICE_LABEL }
        input(type: "text", id: "service_price", name: field_name(:price), value: @service.price, required: true,
          inputmode: "decimal", aria: { describedby: PRICE_HINT_ID }, class: CONTROL)
        p(id: PRICE_HINT_ID, class: HINT) { PRICE_HINT }
      end
      render Components::Form::Errors.new(messages: @service.errors[:price_cents])
    end
  end

  def field_name(attribute) = @collection ? "services[][#{attribute}]" : "service[#{attribute}]"
end
