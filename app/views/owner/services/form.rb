class Views::Owner::Services::Form < Views::Base
  include Components::Form::Styles

  NEW_TITLE = "Novo serviço".freeze
  EDIT_TITLE = "Editar serviço".freeze
  SUBTITLE = "Como ele aparece para a cliente e quanto tempo ocupa a sua agenda.".freeze
  CREATE_LABEL = "Cadastrar serviço".freeze
  UPDATE_LABEL = "Salvar alterações".freeze
  DURATION_HINT_ID = Components::Owner::Service::Fields::DURATION_HINT_ID
  PRICE_HINT_ID = Components::Owner::Service::Fields::PRICE_HINT_ID
  PRICE_HINT = Components::Owner::Service::Fields::PRICE_HINT

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
      render Components::Owner::Service::Fields.new(service: @service)
      form.submit submit_label, class: SUBMIT
    end
  end
end
