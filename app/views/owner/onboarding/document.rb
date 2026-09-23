class Views::Owner::Onboarding::Document < Views::Base
  include Components::Form::Styles

  TITLE = "Zubio".freeze

  WELCOME_TITLE = "Vamos montar a sua página de agendamentos".freeze
  WELCOME_SUBTITLE = "Cinco perguntas rápidas. No fim você sai com um link para mandar para os seus clientes.".freeze
  WELCOME_GROUPS = [ "Sua marca: nome, logo e cor", "O que você cobra", "Quando você atende" ].freeze
  START_LABEL = "Começar".freeze
  WELCOME_NOTE = "Leva menos de três minutos. Dá para mudar tudo depois.".freeze

  BRAND_GROUP = "Sua marca".freeze
  CHARGE_GROUP = "O que você cobra".freeze
  ATTEND_GROUP = "Quando você atende".freeze

  CONTINUE_LABEL = "Continuar".freeze
  SKIP_LABEL = "Pular por enquanto".freeze
  SUBMIT_LABEL = "Ver minha página".freeze

  SERVICES_TITLE = "Cadastre o que você faz".freeze
  SERVICES_SUBTITLE = "Adicione aqui os seus serviços".freeze
  NEW_SERVICE_LABEL = "Novo serviço".freeze
  ADD_SERVICE_LABEL = "Adicionar à lista".freeze
  SERVICES_HELP = "Sem preço fixo? Deixe em branco: o cliente vê \"sob consulta\".".freeze
  EDIT_LABEL = "Editar".freeze
  REMOVE_LABEL = "Remover".freeze

  HOURS_TITLE = "Em quais dias você atende?".freeze
  HOURS_SUBTITLE = "Depois você ajusta o horário de cada dia separadamente.".freeze

  MAIN_CLASS = "mx-auto flex min-h-dvh w-full max-w-md flex-col bg-canvas".freeze
  CONTROLLER_CLASS = "flex min-h-0 flex-grow flex-col".freeze

  WELCOME_CLASS = "flex flex-grow flex-col justify-between px-6 pt-8 pb-6".freeze
  WELCOME_HEADING_CLASS = "mt-5 text-[26px] leading-[1.15] font-extrabold tracking-tight text-balance text-ink".freeze
  WELCOME_SUBTITLE_CLASS = "mt-2 text-[15px] leading-relaxed text-ink-muted".freeze
  WELCOME_GROUPS_CLASS = "mt-0.5 flex flex-col gap-2".freeze
  WELCOME_GROUP_ROW_CLASS = "flex items-center gap-2.5 text-sm text-ink-muted".freeze
  WELCOME_MARKER_CLASS = "grid h-5.5 w-5.5 flex-none place-items-center rounded-full bg-[#E6E1FD] text-[11px] font-extrabold text-[#4830C4]".freeze
  WELCOME_FOOTER_CLASS = "flex flex-col gap-3".freeze
  WELCOME_BUTTON_CLASS = "min-h-13 w-full rounded-xl bg-brand-600 text-base font-extrabold text-on-brand".freeze
  WELCOME_NOTE_CLASS = "text-center text-xs text-ink-subtle".freeze

  SERVICES_TITLE_CLASS = "text-2xl leading-tight font-extrabold tracking-tight text-balance text-ink".freeze
  SERVICES_SUBTITLE_CLASS = "text-sm leading-relaxed text-ink-muted".freeze
  SERVICES_LIST_CLASS = "flex flex-col gap-2".freeze
  SERVICE_ROW_CLASS = "flex items-center gap-3 rounded-xl border border-line bg-surface px-3.5 py-3".freeze
  SERVICE_TEXT_CLASS = "min-w-0 flex-grow".freeze
  SERVICE_NAME_CLASS = "block truncate text-sm font-bold text-ink".freeze
  SERVICE_META_CLASS = "block text-xs text-ink-muted".freeze
  SERVICE_ACTION_CLASS = "grid h-9 w-9 flex-none place-items-center rounded-lg border border-line bg-surface".freeze
  SERVICE_ICON_CLASS = "h-4 w-4".freeze
  NEW_SERVICE_CARD_CLASS = "grid gap-3 rounded-2xl border-2 border-brand-600 bg-surface p-4 shadow-[0_2px_8px_rgba(44,108,176,0.12)]".freeze
  NEW_SERVICE_LABEL_CLASS = "text-xs font-medium uppercase tracking-wide text-brand-ink".freeze
  ADD_SERVICE_BUTTON_CLASS = "flex min-h-11.5 items-center justify-center gap-2 rounded-lg bg-brand-600 text-[15px] font-bold text-on-brand".freeze
  SERVICES_HELP_CLASS = "text-xs leading-snug text-ink-subtle".freeze

  HOURS_TITLE_CLASS = "text-[28px] leading-tight font-extrabold tracking-tight text-balance text-ink".freeze
  HOURS_SUBTITLE_CLASS = "text-sm leading-relaxed text-ink-muted".freeze

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
      main(class: MAIN_CLASS) do
        div(class: CONTROLLER_CLASS, data: root_data) do
          form_with(url: owner_onboarding_path, method: :post, class: CONTROLLER_CLASS,
            data: { turbo: false, action: "input->onboarding#save change->onboarding#save submit->onboarding#submit" }) do
            render_welcome
            render Components::Owner::Onboarding::Screen.new(section: "colors", group: BRAND_GROUP, position: 1, primary: CONTINUE_LABEL, hidden: @open_section != "colors") do
              render Components::Owner::BrandQuestion::Colors.new(tenant: @tenant, branding: @branding)
            end
            render Components::Owner::Onboarding::Screen.new(section: "name", group: BRAND_GROUP, position: 2, primary: CONTINUE_LABEL, hidden: @open_section != "name") do
              render Components::Owner::BrandQuestion::Name.new(tenant: @tenant, branding: @branding, deriving: true)
            end
            render Components::Owner::Onboarding::Screen.new(section: "logo", group: BRAND_GROUP, position: 3, primary: CONTINUE_LABEL, secondary: SKIP_LABEL, hidden: @open_section != "logo") do
              render Components::Owner::BrandQuestion::Logo.new(tenant: @tenant, branding: @branding, direct_upload_url: @direct_upload_url, onboarding: true)
            end
            render Components::Owner::Onboarding::Screen.new(section: "services", group: CHARGE_GROUP, position: 4, primary: CONTINUE_LABEL, count: true, hidden: @open_section != "services") do
              render_services
            end
            render Components::Owner::Onboarding::Screen.new(section: "working_hours", group: ATTEND_GROUP, position: 5, primary: SUBMIT_LABEL, submit: true, hidden: @open_section != "working_hours") do
              render_working_hours
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
    section(class: WELCOME_CLASS, hidden: @open_section != "welcome", data: { onboarding_target: "section", onboarding_section: "welcome" }) do
      render Components::Platform::Emblem.new(size: :onboarding)
      h1(class: WELCOME_HEADING_CLASS) { WELCOME_TITLE }
      p(class: WELCOME_SUBTITLE_CLASS) { WELCOME_SUBTITLE }
      div(class: WELCOME_GROUPS_CLASS) { WELCOME_GROUPS.each_with_index { |text, index| render_welcome_group(text, index) } }
      div(class: WELCOME_FOOTER_CLASS) do
        button(type: "button", class: WELCOME_BUTTON_CLASS, data: { action: "onboarding#next" }) { START_LABEL }
        p(class: WELCOME_NOTE_CLASS) { WELCOME_NOTE }
      end
    end
  end

  def render_welcome_group(text, index)
    div(class: WELCOME_GROUP_ROW_CLASS) do
      span(class: WELCOME_MARKER_CLASS) { (index + 1).to_s }
      plain text
    end
  end

  def render_services
    h1(class: SERVICES_TITLE_CLASS) { SERVICES_TITLE }
    p(class: SERVICES_SUBTITLE_CLASS) { SERVICES_SUBTITLE }
    div(class: SERVICES_LIST_CLASS, data: services_list_data) { @services.each { |service| render_service_row(service) } }
    template(data: { onboarding_target: "serviceRowTemplate" }) { render_service_row(Service.new) }
    render_new_service_card
  end

  def services_list_data
    data = { onboarding_target: "servicesList" }
    data[:onboarding_services_prefilled] = true if @services.any?
    data
  end

  def render_service_row(service)
    div(class: SERVICE_ROW_CLASS, data: { service_row: true }) do
      div(class: SERVICE_TEXT_CLASS) do
        span(class: SERVICE_NAME_CLASS) { service.name }
        span(class: SERVICE_META_CLASS) { service_meta(service) }
        render Components::Form::Errors.new(messages: service.errors.full_messages)
      end
      render_service_action(EDIT_LABEL, "onboarding#editService") { render_edit_icon }
      render_service_action(REMOVE_LABEL, "onboarding#removeService") { render_remove_icon }
      input(type: "hidden", name: "services[][name]", value: service.name, data: { service_field: "name" })
      input(type: "hidden", name: "services[][duration_minutes]", value: service.duration_minutes, data: { service_field: "duration_minutes" })
      input(type: "hidden", name: "services[][price]", value: service.price, data: { service_field: "price" })
    end
  end

  def service_meta(service)
    return "" if service.duration_minutes.blank?

    "#{Service::Duration.label(service.duration_minutes)} · #{Service::Price.label(service.price_cents)}"
  end

  def render_service_action(label, action)
    button(type: "button", class: SERVICE_ACTION_CLASS, aria_label: label, data: { action: action }) { yield }
  end

  def render_edit_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "#{SERVICE_ICON_CLASS} text-ink-muted") do |icon|
      icon.path(d: "M12 20h9")
      icon.path(d: "M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z")
    end
  end

  def render_remove_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "#{SERVICE_ICON_CLASS} text-danger") do |icon|
      icon.path(d: "M4 7h16")
      icon.path(d: "M9 7V5h6v2")
      icon.path(d: "M6 7l1 13h10l1-13")
    end
  end

  def render_new_service_card
    div(class: NEW_SERVICE_CARD_CLASS) do
      span(class: NEW_SERVICE_LABEL_CLASS) { NEW_SERVICE_LABEL }
      render Components::Owner::Service::Fields.new(service: Service.new, onboarding: true)
      button(type: "button", class: ADD_SERVICE_BUTTON_CLASS, data: { action: "onboarding#addService" }) do
        render_add_service_icon
        plain ADD_SERVICE_LABEL
      end
      p(class: SERVICES_HELP_CLASS) { SERVICES_HELP }
    end
  end

  def render_add_service_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.4", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "h-4.5 w-4.5") do |icon|
      icon.path(d: "M12 5v14M5 12h14")
    end
  end

  def render_working_hours
    h1(class: HOURS_TITLE_CLASS) { HOURS_TITLE }
    p(class: HOURS_SUBTITLE_CLASS) { HOURS_SUBTITLE }
    render Components::Owner::WorkingHours::Fields.new
  end
end
