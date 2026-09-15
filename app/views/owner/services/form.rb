class Views::Owner::Services::Form < Views::Base
  include Components::Form::Styles

  NEW_TITLE = "Novo serviço".freeze
  EDIT_TITLE = "Editar serviço".freeze
  SUBTITLE = "Como ele aparece para a cliente e quanto tempo ocupa a sua agenda.".freeze
  NAME_LABEL = "Nome".freeze
  DESCRIPTION_LABEL = "Descrição (opcional)".freeze
  DURATION_LABEL = "Duração (minutos)".freeze
  DURATION_HINT = "Múltiplos de #{Service::DURATION_STEP_MINUTES} minutos, até #{Service::MAX_DURATION_MINUTES.minutes.in_hours.to_i} horas.".freeze
  PRICE_LABEL = "Preço (R$)".freeze
  PRICE_HINT = "Em reais, com vírgula nos centavos: 90,00.".freeze
  CREATE_LABEL = "Cadastrar serviço".freeze
  UPDATE_LABEL = "Salvar alterações".freeze
  DURATION_HINT_ID = "service-duration-hint".freeze
  PRICE_HINT_ID = "service-price-hint".freeze
  DESCRIPTION_ROWS = 3

  def initialize(tenant:, branding:, service:, current_section:)
    @tenant = tenant
    @branding = branding
    @service = service
    @current_section = current_section
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{form_title} · #{@tenant.name}", branding: @branding) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section)
      render Components::Owner::FormCard.new(title: form_title, subtitle: SUBTITLE) { render_form }
    end
  end

  private

  def form_title = @service.persisted? ? EDIT_TITLE : NEW_TITLE

  def submit_label = @service.persisted? ? UPDATE_LABEL : CREATE_LABEL

  def render_form
    form_with(model: [ :owner, @service ], class: Components::Owner::FormCard::FORM_CLASS) do |form|
      render_name_field(form)
      render_description_field(form)
      render_duration_field(form)
      render_price_field(form)
      form.submit submit_label, class: SUBMIT
    end
  end

  def render_name_field(form)
    div(data: { field: "name" }) do
      form.label :name, NAME_LABEL, class: LABEL
      form.text_field :name, required: true, maxlength: Service::NAME_MAX_LENGTH, class: CONTROL
      render Components::Form::Errors.new(messages: @service.errors[:name])
    end
  end

  def render_description_field(form)
    div(data: { field: "description" }) do
      form.label :description, DESCRIPTION_LABEL, class: LABEL
      form.textarea :description, rows: DESCRIPTION_ROWS, maxlength: Service::DESCRIPTION_MAX_LENGTH, class: TEXTAREA
      render Components::Form::Errors.new(messages: @service.errors[:description])
    end
  end

  def render_duration_field(form)
    div(data: { field: "duration_minutes" }) do
      form.label :duration_minutes, DURATION_LABEL, class: LABEL
      form.number_field :duration_minutes, required: true,
        min: Service::MIN_DURATION_MINUTES, max: Service::MAX_DURATION_MINUTES, step: Service::DURATION_STEP_MINUTES,
        aria: { describedby: DURATION_HINT_ID }, class: CONTROL
      p(id: DURATION_HINT_ID, class: HINT) { DURATION_HINT }
      render Components::Form::Errors.new(messages: @service.errors[:duration_minutes])
    end
  end

  def render_price_field(form)
    div(data: { field: "price" }) do
      form.label :price, PRICE_LABEL, class: LABEL
      form.text_field :price, required: true, inputmode: "decimal", aria: { describedby: PRICE_HINT_ID }, class: CONTROL
      p(id: PRICE_HINT_ID, class: HINT) { PRICE_HINT }
      render Components::Form::Errors.new(messages: @service.errors[:price_cents])
    end
  end
end
