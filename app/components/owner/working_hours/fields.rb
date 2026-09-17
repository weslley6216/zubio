class Components::Owner::WorkingHours::Fields < Components::Base
  include Components::Form::Styles

  WEEKDAYS_LABEL = "Dias de atendimento".freeze
  RANGE_LABEL = "Horário de atendimento".freeze
  OPENS_LABEL = "Abre".freeze
  CLOSES_LABEL = "Fecha".freeze
  BREAK_LABEL = "Intervalo (opcional)".freeze
  BREAK_STARTS_LABEL = "Início do intervalo".freeze
  BREAK_ENDS_LABEL = "Fim do intervalo".freeze

  WEEKDAYS_CLASS = "mt-4 grid grid-cols-4 gap-2 sm:grid-cols-7".freeze
  DAY_CLASS = "flex flex-col items-center gap-1 rounded-lg border border-line px-2 py-2 text-xs text-ink".freeze
  RANGE_CLASS = "mt-4 grid grid-cols-2 gap-3".freeze

  def view_template
    render_weekdays
    render_range(RANGE_LABEL, :opens_at, OPENS_LABEL, :closes_at, CLOSES_LABEL)
    render_range(BREAK_LABEL, :break_starts_at, BREAK_STARTS_LABEL, :break_ends_at, BREAK_ENDS_LABEL)
  end

  private

  def render_weekdays
    div do
      span(class: LABEL) { WEEKDAYS_LABEL }
      div(class: WEEKDAYS_CLASS) do
        WorkingHour::WEEKDAYS.each { |weekday| render_weekday_checkbox(weekday) }
      end
    end
  end

  def render_weekday_checkbox(weekday)
    label(class: DAY_CLASS) do
      input(type: "checkbox", name: "working_hours[weekdays][]", value: weekday, class: CHECKBOX)
      plain WorkingHour::WEEKDAY_NAMES[weekday].first(3)
    end
  end

  def render_range(legend, starts_name, starts_label, ends_name, ends_label)
    div do
      span(class: LABEL) { legend }
      div(class: RANGE_CLASS) do
        render_time_field(starts_name, starts_label)
        render_time_field(ends_name, ends_label)
      end
    end
  end

  def render_time_field(name, label_text)
    div do
      label(for: "working_hours_#{name}", class: LABEL) { label_text }
      input(type: "time", id: "working_hours_#{name}", name: "working_hours[#{name}]", step: WorkingHour::MINUTE_STEP * 60, class: CONTROL)
    end
  end
end
