class Views::Owner::Onboarding::Final < Views::Base
  TITLE = "Sua página está no ar".freeze
  SUBTITLE = "Agora é só mandar o link. Quem abrir já consegue marcar horário.".freeze
  CONFIGURED_LABEL = "O que você configurou".freeze
  EDIT_LABEL = "Editar".freeze
  LOGO_NOTICE = "Sem logo ainda? Você pode subir depois, em Configurações.".freeze
  DASHBOARD_LABEL = "Ir para o meu painel".freeze
  NO_SERVICES = "Nenhum serviço cadastrado ainda.".freeze
  ADD_SERVICE_LABEL = "Cadastrar o primeiro serviço".freeze
  NO_DAYS = "Nenhum dia definido ainda.".freeze

  MAIN_CLASS = "mx-auto flex min-h-dvh w-full max-w-md flex-col bg-canvas".freeze
  BANNER_CLASS = "flex flex-col gap-3.5 bg-brand-600 px-6 pt-8.5 pb-10 text-on-brand".freeze
  BADGE_CLASS = "grid h-14 w-14 place-items-center rounded-full bg-white/22".freeze
  BADGE_ICON_CLASS = "h-7.5 w-7.5".freeze
  HEADING_CLASS = "text-[27px] leading-tight font-extrabold tracking-tight text-balance".freeze
  SUBTITLE_CLASS = "text-sm leading-relaxed opacity-[0.92]".freeze

  BODY_CLASS = "-mt-5 flex flex-grow flex-col gap-3.5 px-6 pb-6".freeze
  CONFIGURED_LABEL_CLASS = "text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  ROWS_CLASS = "grid gap-2".freeze
  ROW_CLASS = "flex items-center gap-3 rounded-xl border border-line bg-surface px-4 py-3.5".freeze
  ROW_TEXT_CLASS = "min-w-0 flex-grow".freeze
  ROW_PRIMARY_CLASS = "block truncate text-sm font-bold text-ink".freeze
  ROW_SECONDARY_CLASS = "block text-xs text-ink-muted".freeze
  ROW_EDIT_CLASS = "text-[13px] font-bold text-brand-ink".freeze
  LOGO_NOTICE_CLASS = "flex items-center gap-3 rounded-xl border border-dashed border-line-strong bg-surface px-4 py-3.5 text-[13px] leading-relaxed text-ink-muted".freeze
  LOGO_NOTICE_ICON_CLASS = "h-5 w-5 flex-none text-ink-muted".freeze
  FOOTER_CLASS = "mt-auto flex flex-col gap-2.5".freeze
  DASHBOARD_LINK_CLASS = "grid min-h-13 place-items-center rounded-xl bg-brand-600 text-base font-extrabold text-on-brand".freeze
  ADD_SERVICE_CLASS = "text-[13px] font-bold text-brand-ink".freeze

  def initialize(tenant:, branding:, owner_name:, services:, working_hours:, logo_attached:)
    @tenant = tenant
    @branding = branding
    @owner_name = owner_name
    @services = services
    @working_hours = working_hours
    @logo_attached = logo_attached
  end

  def view_template
    render Views::Layouts::Application.new(title: TITLE, branding: @branding, view_transition: true) do
      main(class: MAIN_CLASS) do
        render_banner
        render_body
      end
    end
  end

  private

  def render_banner
    div(class: BANNER_CLASS) do
      div(class: BADGE_CLASS) { render_check_icon }
      h1(class: HEADING_CLASS) { "#{TITLE}, #{first_name}" }
      p(class: SUBTITLE_CLASS) { SUBTITLE }
    end
  end

  def render_check_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.6", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BADGE_ICON_CLASS) do |icon|
      icon.path(d: "M20 6 9 17l-5-5")
    end
  end

  def render_body
    div(class: BODY_CLASS) do
      render Components::Owner::ShareLink.new(host: @tenant.canonical_host)
      span(class: CONFIGURED_LABEL_CLASS) { CONFIGURED_LABEL }
      div(class: ROWS_CLASS) do
        render_brand_row
        render_services_row
        render_schedule_row
      end
      render_logo_notice unless @logo_attached
      render_footer
    end
  end

  def render_brand_row
    div(class: ROW_CLASS) do
      render Components::Owner::Emblem.new(tenant: @tenant, branding: @branding, size: :row)
      div(class: ROW_TEXT_CLASS) { span(class: ROW_PRIMARY_CLASS) { @tenant.name } }
      a(href: edit_owner_brand_name_path, class: ROW_EDIT_CLASS) { EDIT_LABEL }
    end
  end

  def render_services_row
    div(class: ROW_CLASS) do
      if @services.empty?
        div(class: ROW_TEXT_CLASS) { span(class: ROW_PRIMARY_CLASS) { NO_SERVICES } }
      else
        div(class: ROW_TEXT_CLASS) do
          span(class: ROW_PRIMARY_CLASS) { pluralized_services }
          span(class: ROW_SECONDARY_CLASS) { services_durations }
        end
      end
    end
  end

  def render_schedule_row
    div(class: ROW_CLASS) do
      if @working_hours.blank?
        div(class: ROW_TEXT_CLASS) { span(class: ROW_PRIMARY_CLASS) { NO_DAYS } }
      else
        summary = WorkingHour::Summary.new(@working_hours)
        div(class: ROW_TEXT_CLASS) do
          span(class: ROW_PRIMARY_CLASS) { summary.weekdays_label }
          span(class: ROW_SECONDARY_CLASS) { summary.hours_label }
        end
      end
    end
  end

  def render_logo_notice
    div(class: LOGO_NOTICE_CLASS) do
      render_logo_icon
      plain LOGO_NOTICE
    end
  end

  def render_logo_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: LOGO_NOTICE_ICON_CLASS) do |icon|
      icon.path(d: "M12 3v12")
      icon.path(d: "m7 10 5 5 5-5")
      icon.path(d: "M5 21h14")
    end
  end

  def render_footer
    div(class: FOOTER_CLASS) do
      a(href: owner_dashboard_path, class: DASHBOARD_LINK_CLASS) { DASHBOARD_LABEL }
      a(href: new_owner_service_path, class: ADD_SERVICE_CLASS) { ADD_SERVICE_LABEL } if @services.empty?
    end
  end

  def first_name = @owner_name.to_s.split.first

  def pluralized_services = "#{@services.size} #{@services.size == 1 ? 'serviço' : 'serviços'}"

  def services_durations = @services.map { |service| Service::Duration.label(service.duration_minutes) }.join(" · ")
end
