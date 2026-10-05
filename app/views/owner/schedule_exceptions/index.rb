class Views::Owner::ScheduleExceptions::Index < Views::Base
  include Components::Form::Styles
  include Phlex::Rails::Helpers::ButtonTo

  TITLE = "Folgas e feriados".freeze
  SUBTITLE = "Os dias em que você fecha ou atende diferente.".freeze
  DATE_LABEL = "Data".freeze
  ATTENDS_LABEL = "Atendo neste dia".freeze
  OPENS_LABEL = "Abre".freeze
  CLOSES_LABEL = "Fecha".freeze
  REASON_LABEL = "Motivo · opcional".freeze
  REASON_PLACEHOLDER = "Feriado, viagem, médico…".freeze
  SUBMIT_LABEL = "Registrar".freeze
  CLOSED_LABEL = "Fechado".freeze
  REDUCED_LABEL = "Horário reduzido".freeze
  REMOVE_LABEL = "Remover".freeze
  UPCOMING_LABEL = "Próximas".freeze
  WINDOW_JOINER = "às".freeze
  EMPTY_TITLE = "Nenhuma folga por vir".freeze
  EMPTY_BODY = "Registre acima a primeira data em que você não atende ou atende diferente.".freeze
  MONTHS = %w[jan fev mar abr mai jun jul ago set out nov dez].freeze
  TRASH_ICON = "M4 7h16M9 7V5h6v2M6 7l1 13h10l1-13".freeze

  PAGE_CLASS = "mx-auto grid w-full max-w-2xl gap-6 px-6 py-10".freeze
  HEADING_CLASS = "mt-2 text-xl font-extrabold tracking-tight text-ink".freeze
  SUBTITLE_CLASS = "text-sm text-ink-muted".freeze
  FORM_CLASS = "mt-4 grid gap-3 rounded-xl border border-line bg-surface p-4".freeze
  FIELD_CLASS = "grid gap-1.5".freeze
  FIELD_LABEL_CLASS = "#{SECTION_LABEL} text-ink-muted".freeze
  ATTENDS_ROW_CLASS = "flex items-center justify-between gap-3 rounded-lg border border-line bg-surface-2 px-3.5 py-3".freeze
  ATTENDS_TEXT_CLASS = "text-sm font-bold text-ink".freeze
  WINDOW_CLASS = "hidden grid-cols-2 gap-2 group-has-checked:grid".freeze
  UPCOMING_CLASS = "grid gap-2.5".freeze
  UPCOMING_LABEL_CLASS = "#{SECTION_LABEL} text-ink-muted".freeze
  LIST_CLASS = "grid gap-2.5".freeze
  ROW_CLASS = "flex items-center gap-3 rounded-xl border border-line bg-surface px-4 py-3.5".freeze
  DATE_BLOCK_CLASS = "grid w-11 flex-none justify-items-center".freeze
  DAY_CLASS = "text-[19px] font-extrabold leading-tight tabular-nums text-ink".freeze
  MONTH_CLASS = "text-[10px] font-bold uppercase tracking-wide text-ink-muted".freeze
  DETAIL_CLASS = "grid min-w-0 flex-1 gap-1".freeze
  REASON_CLASS = "text-[13px] text-ink-muted".freeze
  WINDOW_TEXT_CLASS = "text-[13px] font-bold tabular-nums text-ink".freeze
  REMOVE_CLASS = "grid h-11 w-11 flex-none cursor-pointer place-items-center rounded-lg border border-line bg-surface text-danger hover:bg-surface-2".freeze
  EMPTY_CLASS = "grid gap-2 rounded-xl border border-line bg-surface p-6".freeze
  EMPTY_TITLE_CLASS = "text-lg font-bold text-ink".freeze
  EMPTY_BODY_CLASS = "text-sm text-ink-muted".freeze

  def initialize(tenant:, branding:, exceptions:, exception:, current_section:)
    @tenant = tenant
    @branding = branding
    @exceptions = exceptions
    @exception = exception
    @current_section = current_section
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section)
      main(class: PAGE_CLASS) do
        render Components::Owner::SettingsBackLink.new
        render_heading
        render_form
        @exceptions.empty? ? render_empty_state : render_list
      end
    end
  end

  private

  def render_heading
    h1(class: HEADING_CLASS) { TITLE }
    p(class: SUBTITLE_CLASS) { SUBTITLE }
  end

  def render_form
    form_with(url: owner_schedule_exceptions_path, class: FORM_CLASS) do |form|
      render_date_field
      render_attendance
      render_reason_field
      form.submit(SUBMIT_LABEL, class: SUBMIT)
    end
  end

  def render_date_field
    div(class: FIELD_CLASS) do
      label(for: "schedule_exception_occurs_on", class: FIELD_LABEL_CLASS) { DATE_LABEL }
      input(type: "date", id: "schedule_exception_occurs_on", name: "schedule_exception[occurs_on]",
        value: @exception.occurs_on&.iso8601, min: Date.current.iso8601, class: CONTROL)
      render Components::Form::Errors.new(messages: @exception.errors[:occurs_on])
    end
  end

  def render_attendance
    div(class: "group grid gap-3") do
      div(class: ATTENDS_ROW_CLASS) do
        span(class: ATTENDS_TEXT_CLASS) { ATTENDS_LABEL }
        render Components::Toggle.new(name: "schedule_exception[attends]", value: "1",
          checked: attending?, id: "schedule_exception_attends")
      end
      div(class: WINDOW_CLASS) do
        render_time_field("opens_at", OPENS_LABEL, @exception.opens_at)
        render_time_field("closes_at", CLOSES_LABEL, @exception.closes_at)
      end
      render Components::Form::Errors.new(messages: @exception.errors[:opens_at] + @exception.errors[:closes_at])
    end
  end

  def render_time_field(key, label_text, value)
    input(type: "time", name: "schedule_exception[#{key}]", value: value&.strftime("%H:%M"),
      aria_label: label_text, step: HourWindow::MINUTE_STEP * 60, class: CONTROL)
  end

  def render_reason_field
    div(class: FIELD_CLASS) do
      label(for: "schedule_exception_reason", class: FIELD_LABEL_CLASS) { REASON_LABEL }
      input(type: "text", id: "schedule_exception_reason", name: "schedule_exception[reason]",
        value: @exception.reason, placeholder: REASON_PLACEHOLDER, class: CONTROL)
    end
  end

  def render_list
    section(class: UPCOMING_CLASS, data: { exceptions: true }) do
      span(class: UPCOMING_LABEL_CLASS) { UPCOMING_LABEL }
      ul(class: LIST_CLASS) do
        @exceptions.each { |exception| render_row(exception) }
      end
    end
  end

  def render_row(exception)
    li(class: ROW_CLASS, data: { exception: exception.id }) do
      render_date_block(exception)
      render_detail(exception)
      render_remove(exception)
    end
  end

  def render_date_block(exception)
    div(class: DATE_BLOCK_CLASS) do
      span(class: DAY_CLASS) { exception.occurs_on.strftime("%d") }
      span(class: MONTH_CLASS) { MONTHS[exception.occurs_on.month - 1] }
    end
  end

  def render_badge(exception)
    if exception.closed?
      render Components::Badge.new(text: CLOSED_LABEL, tone: :muted)
    else
      render Components::Badge.new(text: REDUCED_LABEL, tone: :brand)
    end
  end

  def render_detail(exception)
    div(class: DETAIL_CLASS, data: { detail: true }) do
      render_badge(exception)
      if exception.closed?
        span(class: REASON_CLASS, data: { reason: true }) { exception.reason } if exception.reason.present?
      else
        span(class: WINDOW_TEXT_CLASS, data: { window: true }) { window_label(exception) }
      end
    end
  end

  def render_remove(exception)
    button_to(owner_schedule_exception_path(exception), method: :delete, class: REMOVE_CLASS, aria_label: REMOVE_LABEL) do
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
        stroke_linejoin: "round", aria_hidden: "true", class: "h-[17px] w-[17px]") { |icon| icon.path(d: TRASH_ICON) }
    end
  end

  def render_empty_state
    div(class: EMPTY_CLASS, data: { empty: true }) do
      h2(class: EMPTY_TITLE_CLASS) { EMPTY_TITLE }
      p(class: EMPTY_BODY_CLASS) { EMPTY_BODY }
    end
  end

  def attending? = @exception.closed == false

  def window_label(exception) = "#{exception.opens_at.strftime('%H:%M')} #{WINDOW_JOINER} #{exception.closes_at.strftime('%H:%M')}"
end
