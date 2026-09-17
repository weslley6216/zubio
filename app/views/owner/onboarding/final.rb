class Views::Owner::Onboarding::Final < Views::Base
  TITLE = "Sua página está no ar!".freeze
  SUMMARY_BRAND_LABEL = "Marca".freeze
  SUMMARY_SERVICES_LABEL = "Serviços".freeze
  SUMMARY_DAYS_LABEL = "Dias de atendimento".freeze
  NO_SERVICES = "Nenhum serviço cadastrado ainda.".freeze
  ADD_SERVICE_LABEL = "Cadastrar o primeiro serviço".freeze
  NO_DAYS = "Nenhum dia definido ainda.".freeze
  DASHBOARD_LABEL = "Ver meu painel".freeze

  TITLE_CLASS = "text-xl font-extrabold tracking-tight text-ink".freeze
  SUMMARY_CLASS = "mt-4 grid gap-3".freeze
  ROW_LABEL_CLASS = "text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  ROW_VALUE_CLASS = "text-sm text-ink".freeze
  ADD_SERVICE_CLASS = "text-sm font-bold text-brand-ink".freeze
  DASHBOARD_LINK_CLASS = "mt-4 grid h-12 place-items-center rounded-md bg-brand-600 px-4 font-medium text-on-brand".freeze

  def initialize(tenant:, branding:, services_count:, working_hours:)
    @tenant = tenant
    @branding = branding
    @services_count = services_count
    @working_hours = working_hours
  end

  def view_template
    render Views::Layouts::Application.new(title: TITLE, branding: @branding, view_transition: true) do
      main(class: Components::Owner::FormCard::PAGE_CLASS) do
        section(class: Components::Owner::FormCard::CARD_CLASS) do
          h1(class: TITLE_CLASS) { TITLE }
          render Components::Owner::ShareLink.new(host: @tenant.canonical_host)
          render_summary
          a(href: owner_dashboard_path, class: DASHBOARD_LINK_CLASS) { DASHBOARD_LABEL }
        end
      end
    end
  end

  private

  def render_summary
    div(class: SUMMARY_CLASS) do
      render_row(SUMMARY_BRAND_LABEL) { plain @tenant.name }
      render_services_row
      render_row(SUMMARY_DAYS_LABEL) { plain days_summary }
    end
  end

  def render_row(label)
    div do
      span(class: ROW_LABEL_CLASS) { label }
      p(class: ROW_VALUE_CLASS) { yield }
    end
  end

  def render_services_row
    div do
      span(class: ROW_LABEL_CLASS) { SUMMARY_SERVICES_LABEL }
      if @services_count.zero?
        p(class: ROW_VALUE_CLASS) { NO_SERVICES }
        a(href: new_owner_service_path, class: ADD_SERVICE_CLASS) { ADD_SERVICE_LABEL }
      else
        p(class: ROW_VALUE_CLASS) { pluralized_services }
      end
    end
  end

  def pluralized_services = "#{@services_count} #{@services_count == 1 ? 'serviço' : 'serviços'}"

  def days_summary
    return NO_DAYS if @working_hours.blank?

    @working_hours.uniq(&:weekday).map(&:weekday_name).join(", ")
  end
end
