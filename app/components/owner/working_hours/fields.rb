class Components::Owner::WorkingHours::Fields < Components::Base
  include Components::Form::Styles

  ALL_DAYS_LABEL = "Todos".freeze
  RANGE_LABEL = "Horário desses dias".freeze
  OPENS_LABEL = "Abre".freeze
  CLOSES_LABEL = "Fecha".freeze
  RANGE_JOINER = "até".freeze
  BREAK_TOGGLE_LABEL = "Paro para o almoço".freeze
  BREAK_STARTS_LABEL = "Início do intervalo".freeze
  BREAK_ENDS_LABEL = "Fim do intervalo".freeze
  BREAK_FIELD_ACTION = "input->onboarding#summarizeBreak change->onboarding#summarizeBreak".freeze

  CHIPS_CLASS = "grid grid-cols-4 gap-2".freeze
  CHIP_BASE_CLASS = "grid min-h-13 place-items-center rounded-xl text-sm".freeze
  CHIP_UNCHECKED_CLASS = "border border-line bg-surface font-bold text-ink-subtle peer-checked:border-2 peer-checked:border-brand-600 peer-checked:bg-brand-soft peer-checked:font-extrabold peer-checked:text-brand-ink".freeze
  ALL_DAYS_CLASS = "grid min-h-13 place-items-center rounded-xl border border-dashed border-line-strong bg-surface text-xs font-bold text-ink-muted".freeze
  COUNTER_CLASS = "mt-2 text-xs text-ink-muted".freeze

  RANGE_CARD_CLASS = "mt-4 grid gap-3 rounded-2xl border border-line bg-surface p-4".freeze
  RANGE_LABEL_CLASS = "text-xs font-medium uppercase tracking-wide text-ink-subtle".freeze
  RANGE_ROW_CLASS = "flex items-center gap-2.5".freeze
  RANGE_JOINER_CLASS = "text-sm text-ink-muted".freeze
  RANGE_FIELD_CLASS = "flex-grow min-h-12 justify-center rounded-lg border border-line-strong text-base font-bold".freeze

  BREAK_ROW_CLASS = "flex items-center justify-between gap-3 rounded-[10px] border border-line bg-surface-2 px-3.5 py-3".freeze
  BREAK_TEXT_CLASS = "block text-sm font-bold text-ink".freeze
  BREAK_SUMMARY_CLASS = "block text-xs text-ink-muted empty:hidden".freeze
  BREAK_CLASS = "grid gap-3".freeze
  BREAK_FIELDS_CLASS = "grid grid-cols-2 gap-3".freeze
  TOGGLE_CLASS = "relative inline-flex h-[26px] w-[46px] flex-none cursor-pointer items-center rounded-full bg-line p-[3px] has-checked:bg-brand-600".freeze
  TOGGLE_THUMB_CLASS = "h-5 w-5 rounded-full bg-white transition-transform peer-checked:translate-x-5".freeze

  def view_template
    render_weekdays
    render_schedule_card
  end

  private

  def render_weekdays
    div do
      div(class: CHIPS_CLASS) do
        WorkingHour::WEEKDAYS.each { |weekday| render_weekday_chip(weekday) }
        render_all_days_chip
      end
      span(class: COUNTER_CLASS, data: { onboarding_target: "dayCount" })
    end
  end

  def render_weekday_chip(weekday)
    label(class: "block") do
      input(type: "checkbox", name: "working_hours[weekdays][]", value: weekday, class: "peer sr-only",
        data: { action: "change->onboarding#updateDayCount" })
      span(class: "#{CHIP_BASE_CLASS} #{CHIP_UNCHECKED_CLASS}") { plain WorkingHour::WEEKDAY_NAMES[weekday].first(3) }
    end
  end

  def render_all_days_chip
    button(type: "button", class: ALL_DAYS_CLASS, data: { action: "onboarding#selectAllDays" }) { ALL_DAYS_LABEL }
  end

  def render_schedule_card
    div(class: RANGE_CARD_CLASS, data: { schedule_card: true }) do
      span(class: RANGE_LABEL_CLASS) { RANGE_LABEL }
      div(class: RANGE_ROW_CLASS) do
        render_time_field(:opens_at, OPENS_LABEL)
        span(class: RANGE_JOINER_CLASS) { RANGE_JOINER }
        render_time_field(:closes_at, CLOSES_LABEL)
      end
      render_break
    end
  end

  def render_break
    div(class: BREAK_CLASS) do
      div(class: BREAK_ROW_CLASS) do
        div do
          span(class: BREAK_TEXT_CLASS) { BREAK_TOGGLE_LABEL }
          span(class: BREAK_SUMMARY_CLASS, data: { onboarding_target: "breakSummary" })
        end
        label(class: TOGGLE_CLASS) do
          input(type: "checkbox", class: "peer sr-only", data: { action: "change->onboarding#toggleBreak", onboarding_target: "breakToggle" })
          span(class: TOGGLE_THUMB_CLASS)
        end
      end
      div(class: "#{BREAK_FIELDS_CLASS} hidden", data: { onboarding_target: "break" }) do
        render_time_field(:break_starts_at, BREAK_STARTS_LABEL, action: BREAK_FIELD_ACTION)
        render_time_field(:break_ends_at, BREAK_ENDS_LABEL, action: BREAK_FIELD_ACTION)
      end
    end
  end

  def render_time_field(name, label_text, action: nil)
    input(type: "time", id: "working_hours_#{name}", aria_label: label_text, name: "working_hours[#{name}]",
      step: WorkingHour::MINUTE_STEP * 60, class: RANGE_FIELD_CLASS, data: { action: action })
  end
end
