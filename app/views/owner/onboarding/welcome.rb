class Views::Owner::Onboarding::Welcome < Views::Base
  include Components::Form::Styles

  TITLE = "Vamos deixar sua página pronta".freeze
  SUBTITLE = "Cinco perguntas rápidas, uma de cada vez, até o link pronto pra compartilhar.".freeze
  START_LABEL = "Começar".freeze

  QUESTIONS = {
    "colors" => "Escolha as cores da sua marca",
    "name" => "Dê um nome à sua marca",
    "logo" => "Envie sua logo",
    "services" => "Cadastre seus serviços",
    "working_hours" => "Defina seus dias e horários"
  }.freeze

  TITLE_CLASS = "text-xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "mt-1 text-sm text-ink-muted".freeze
  LIST_CLASS = "mt-4 grid list-decimal gap-2 pl-5 text-sm text-ink".freeze

  def initialize(tenant:, branding:)
    @tenant = tenant
    @branding = branding
  end

  def view_template
    render Views::Layouts::Application.new(title: TITLE, branding: @branding, view_transition: true) do
      main(class: Components::Owner::FormCard::PAGE_CLASS) do
        section(class: Components::Owner::FormCard::CARD_CLASS) do
          h1(class: TITLE_CLASS) { TITLE }
          p(class: SUBTITLE_CLASS) { SUBTITLE }
          render_questions
          form_with(url: owner_onboarding_welcome_path, method: :patch, class: "mt-4") do |form|
            form.submit START_LABEL, class: SUBMIT
          end
        end
      end
    end
  end

  private

  def render_questions
    ol(class: LIST_CLASS) do
      Tenant::ONBOARDING_QUESTIONS.each { |step| li { QUESTIONS.fetch(step) } }
    end
  end
end
