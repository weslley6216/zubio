class Views::Owner::Onboarding::Document < Views::Base
  include Components::Form::Styles

  TITLE = "Zubio".freeze
  START_LABEL = "Começar".freeze
  CONTINUE_LABEL = "Continuar".freeze
  BACK_LABEL = "Voltar".freeze
  SKIP_LABEL = "Pular por enquanto".freeze
  SUBMIT_LABEL = "Publicar minha página".freeze
  ADD_SERVICE_LABEL = "Cadastrar serviço".freeze
  REMOVE_SERVICE_LABEL = "Remover".freeze
  BACK_CLASS = "mt-2 h-11 w-full cursor-pointer text-sm font-medium text-ink-muted".freeze
  BRAND_GROUP = "Sua marca".freeze
  ATTEND_GROUP = "Seu atendimento".freeze
  GROUPS = { "colors" => BRAND_GROUP, "name" => BRAND_GROUP, "logo" => BRAND_GROUP,
             "services" => ATTEND_GROUP, "working_hours" => ATTEND_GROUP }.freeze

  WELCOME_TITLE = "Vamos deixar sua página pronta".freeze
  WELCOME_SUBTITLE = "Cinco perguntas rápidas, uma de cada vez, até o link pronto pra compartilhar.".freeze
  QUESTIONS = {
    "colors" => "Escolha as cores da sua marca",
    "name" => "Dê um nome à sua marca",
    "logo" => "Envie sua logo",
    "services" => "Cadastre seus serviços",
    "working_hours" => "Defina seus dias e horários"
  }.freeze
  SERVICES_SUBTITLE = "Adicione quantos quiser; dá pra editar depois.".freeze
  HOURS_SUBTITLE = "Isso decide quando os clientes podem agendar com você.".freeze

  TITLE_CLASS = "text-xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "mt-1 text-sm text-ink-muted".freeze
  WELCOME_LIST_CLASS = "mt-4 grid list-decimal gap-2 pl-5 text-sm text-ink".freeze
  SERVICES_LIST_CLASS = "mt-4 grid gap-3".freeze
  SERVICE_ROW_CLASS = "grid gap-3 rounded-xl border border-line bg-surface-2 p-3".freeze
  REMOVE_SERVICE_CLASS = "justify-self-end text-xs font-bold text-ink-muted".freeze
  ADD_SERVICE_CLASS = "mt-3 text-sm font-bold text-brand-ink".freeze

  def initialize(tenant:, branding:, services:, open_section:, page_stylesheet:, direct_upload_url:)
    @tenant = tenant
    @branding = branding
    @services = services
    @open_section = open_section
    @page_stylesheet = page_stylesheet
    @direct_upload_url = direct_upload_url
  end

  def view_template
    render Views::Layouts::Application.new(title: TITLE, branding: @branding, page_stylesheet: @page_stylesheet, view_transition: true) do
      main(class: Components::Owner::FormCard::PAGE_CLASS) do
        div(data: root_data) do
          render Components::Owner::Onboarding::Progress.new
          section(class: Components::Owner::FormCard::CARD_CLASS) do
            form_with(url: owner_onboarding_path, method: :post, class: Components::Owner::FormCard::FORM_CLASS,
              data: { turbo: false, action: "input->onboarding#save change->onboarding#save submit->onboarding#submit" }) do
              render_welcome
              render_question("colors") { render Components::Owner::BrandQuestion::Colors.new(tenant: @tenant, branding: @branding) }
              render_question("name") { render Components::Owner::BrandQuestion::Name.new(tenant: @tenant, branding: @branding, deriving: true) }
              render_question("logo", secondary: SKIP_LABEL) { render Components::Owner::BrandQuestion::Logo.new(tenant: @tenant, branding: @branding, direct_upload_url: @direct_upload_url) }
              render_question("services") { render_services }
              render_question("working_hours", last: true) { render_working_hours }
            end
          end
        end
      end
    end
  end

  private

  def root_data
    { controller: "onboarding", onboarding_tenant_value: @tenant.id, onboarding_open_value: @open_section }
  end

  def render_welcome
    section(hidden: @open_section != "welcome",
      data: { onboarding_target: "section", onboarding_section: "welcome" }) do
      h1(class: TITLE_CLASS) { WELCOME_TITLE }
      p(class: SUBTITLE_CLASS) { WELCOME_SUBTITLE }
      ol(class: WELCOME_LIST_CLASS) { QUESTIONS.each_value { |text| li { text } } }
      button(type: "button", class: SUBMIT, data: { action: "onboarding#next" }) { START_LABEL }
    end
  end

  def render_question(name, secondary: nil, last: false)
    section(hidden: @open_section != name,
      data: { onboarding_target: "section", onboarding_section: name,
              onboarding_question: "", onboarding_group: GROUPS.fetch(name) }) do
      yield
      render_primary_action(last)
      button(type: "button", class: BACK_CLASS, data: { action: "onboarding#next" }) { secondary } if secondary
      render_back
    end
  end

  def render_primary_action(last)
    if last
      button(type: "submit", class: SUBMIT) { SUBMIT_LABEL }
    else
      button(type: "button", class: SUBMIT, data: { action: "onboarding#next" }) { CONTINUE_LABEL }
    end
  end

  def render_back
    button(type: "button", class: BACK_CLASS, data: { onboarding_target: "back", action: "onboarding#back" }) { BACK_LABEL }
  end

  def render_services
    h1(class: TITLE_CLASS) { QUESTIONS.fetch("services") }
    p(class: SUBTITLE_CLASS) { SERVICES_SUBTITLE }
    div(class: SERVICES_LIST_CLASS, data: services_list_data) do
      if @services.empty?
        render_service_row(Service.new)
      else
        @services.each { |service| render_service_row(service) }
      end
    end
    button(type: "button", class: ADD_SERVICE_CLASS, data: { action: "onboarding#addService" }) { ADD_SERVICE_LABEL }
    template(data: { onboarding_target: "serviceTemplate" }) { render_service_row(Service.new) }
  end

  def services_list_data
    data = { onboarding_target: "servicesList" }
    data[:onboarding_services_prefilled] = true if @services.any?
    data
  end

  def render_service_row(service)
    div(class: SERVICE_ROW_CLASS, data: { service_row: true }) do
      render Components::Owner::Service::Fields.new(service: service, collection: true)
      button(type: "button", class: REMOVE_SERVICE_CLASS, data: { action: "onboarding#removeService" }) { REMOVE_SERVICE_LABEL }
    end
  end

  def render_working_hours
    h1(class: TITLE_CLASS) { QUESTIONS.fetch("working_hours") }
    p(class: SUBTITLE_CLASS) { HOURS_SUBTITLE }
    render Components::Owner::WorkingHours::Fields.new
  end
end
