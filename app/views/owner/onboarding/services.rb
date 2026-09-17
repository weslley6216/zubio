class Views::Owner::Onboarding::Services < Views::Base
  include Components::Form::Styles

  TITLE = "Zubio".freeze
  EMPTY_LABEL = "Nenhum serviço cadastrado ainda.".freeze
  ADD_LABEL = "Cadastrar serviço".freeze
  LIST_CLASS = "mt-4 grid gap-2".freeze
  ITEM_CLASS = "flex items-center justify-between rounded-lg border border-line bg-surface-2 px-3 py-2 text-sm text-ink".freeze

  def initialize(tenant:, branding:, service:, services:)
    @tenant = tenant
    @branding = branding
    @service = service
    @services = services
  end

  def view_template
    render Views::Layouts::Application.new(title: TITLE, branding: @branding, view_transition: true) do
      main(class: Components::Owner::FormCard::PAGE_CLASS) do
        render Components::Owner::Onboarding::Progress.new(step: "services")
        section(class: Components::Owner::FormCard::CARD_CLASS) do
          render_add_form
          render_list
          render_continue_form
        end
      end
    end
  end

  private

  def render_add_form
    form_with(url: owner_onboarding_services_path, method: :post, class: Components::Owner::FormCard::FORM_CLASS) do |form|
      render Components::Owner::Service::Fields.new(service: @service)
      form.submit ADD_LABEL, class: SUBMIT
    end
  end

  def render_list
    if @services.empty?
      p(class: "mt-4 text-sm text-ink-muted") { EMPTY_LABEL }
    else
      ul(class: LIST_CLASS) { @services.each { |service| li(class: ITEM_CLASS) { plain service.name } } }
    end
  end

  def render_continue_form
    form_with(url: owner_onboarding_services_path, method: :patch, class: "mt-4") do |form|
      form.submit continue_label, class: SUBMIT
    end
  end

  def continue_label = "Continuar (#{pluralized_count})"

  def pluralized_count
    count = @services.size
    "#{count} #{count == 1 ? 'serviço' : 'serviços'}"
  end
end
