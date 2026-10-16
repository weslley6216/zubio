class Views::Owner::WorkingHours::Edit < Views::Base
  TITLE = "Horários da semana".freeze
  SUBTITLE = "Vale para toda semana. Feriado e folga você marca em Folgas e feriados.".freeze
  INVITE = "Você ainda não declarou seu expediente. Ligue os dias em que atende.".freeze
  SUBMIT_LABEL = "Salvar minha semana".freeze
  SUBMIT_NOTE = "Salva a semana inteira de uma vez. Se algum dia estiver errado, nada é gravado.".freeze
  CLOSED_SUFFIX = "Não atendo".freeze
  BREAK_LABEL = "Intervalo".freeze
  ADD_BREAK_LABEL = "Intervalo".freeze
  COPY_LABEL = "Copiar para todos os dias".freeze
  REMOVE_BREAK_LABEL = "Tirar o intervalo".freeze
  OPENS_LABEL = Components::Owner::WorkingHours::Fields::OPENS_LABEL
  CLOSES_LABEL = Components::Owner::WorkingHours::Fields::CLOSES_LABEL
  BREAK_STARTS_LABEL = Components::Owner::WorkingHours::Fields::BREAK_STARTS_LABEL
  BREAK_ENDS_LABEL = Components::Owner::WorkingHours::Fields::BREAK_ENDS_LABEL
  JOINER = Components::Owner::WorkingHours::Fields::RANGE_JOINER

  DAY_CLASS = "group grid min-w-0 gap-2.5 rounded-xl border bg-surface px-4 py-3.5".freeze
  NAME_CLASS = "grow text-[14px] font-extrabold leading-[normal] text-ink bg-surface".freeze
  TOGGLE_TRACK_CLASS = "relative inline-flex h-[26px] w-[46px] flex-none cursor-pointer items-center rounded-full bg-line p-[3px] group-has-checked:bg-brand-600".freeze
  TOGGLE_THUMB_CLASS = "h-5 w-5 rounded-full bg-white shadow-[0_1px_2px_rgba(14,26,36,0.2)] transition-transform group-has-checked:translate-x-5".freeze
  FIELDS_CLASS = "hidden min-w-0 gap-2.5 group-has-checked:grid".freeze
  ROW_CLASS = "flex min-w-0 items-center gap-2".freeze
  FIELD_CLASS = "min-h-11 min-w-0 grow rounded-lg px-3 text-[15px] leading-[normal] font-bold tabular-nums text-ink".freeze
  FIELD_BORDER = "border border-line-strong".freeze
  FIELD_GUILTY_BORDER = "border border-danger".freeze
  JOINER_CLASS = "text-[13px] leading-[normal] text-ink-muted".freeze
  SPACER_CLASS = "w-11 flex-none".freeze
  BREAK_CLASS = "grid min-w-0 gap-1.5".freeze
  BREAK_LABEL_CLASS = "text-[11px] font-bold uppercase tracking-[0.06em] leading-[normal] text-ink-muted".freeze
  REMOVE_CLASS = "grid h-11 w-11 flex-none place-items-center rounded-lg border border-line bg-surface".freeze
  ADD_CLASS = "hidden min-h-10 items-center gap-1.5 self-start justify-self-start rounded-lg border border-dashed border-brand-600 bg-surface px-3 text-[13px] leading-[normal] font-bold text-brand-600".freeze
  COPY_CLASS = "hidden min-h-10 items-center gap-1.5 self-start justify-self-start px-1 text-[13px] leading-[normal] font-bold text-brand-600".freeze
  GROUP_CLASS = "w-full min-w-0 rounded-xl border border-line bg-surface".freeze
  SUMMARY_CLASS = "flex min-h-11 cursor-pointer list-none items-center gap-3 px-4 py-3.5".freeze
  SUMMARY_NAMES_CLASS = "grow text-[14px] font-bold leading-[normal] text-ink-subtle".freeze
  SUMMARY_SUFFIX_CLASS = "flex-none whitespace-nowrap text-[12px] font-semibold leading-[normal] text-ink-subtle".freeze
  GROUP_BODY_CLASS = "grid min-w-0 gap-2.5 px-4 pb-4".freeze
  SUBMIT_CLASS = "h-12 w-full cursor-pointer rounded-[10px] bg-brand-600 text-[15px] leading-[normal] font-extrabold text-on-brand".freeze
  NOTE_CLASS = "text-center text-[12px] leading-[normal] text-ink-muted".freeze
  INVITE_CLASS = "mt-3 rounded-lg border border-line bg-surface-2 p-3 text-sm text-ink-muted".freeze

  def initialize(tenant:, branding:, schedule:, conflicts:, current_section:, subtitle:)
    @tenant = tenant
    @branding = branding
    @schedule = schedule
    @conflicts = conflicts
    @subtitle = subtitle
    @current_section = current_section
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding, flash_in_content: true) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section, subtitle: @subtitle)
      render Components::FlashBanner.new(container_class: "#{Components::Owner::Panel::CONTENT} grid gap-2 pt-4")
      main(class: Components::Owner::FormCard::PAGE_CLASS) do
        render_heading
        render Components::Owner::OutsideHoursNotice.new(conflicts: @conflicts)
        render_invite unless @schedule.any_marked?
        form_with(url: owner_working_hours_path, method: :patch, class: "mt-4 grid min-w-0 gap-2.5", data: { controller: "working-week" }) do |form|
          render_closed_group
          open_weekdays.each_with_index { |weekday, position| render_day(weekday, first_open: position.zero?) }
          div(class: "mt-1.5 grid gap-2") do
            form.submit(SUBMIT_LABEL, class: SUBMIT_CLASS)
            p(class: NOTE_CLASS) { SUBMIT_NOTE }
          end
        end
      end
    end
  end

  private

  def open_weekdays = WorkingHour::WEEKDAYS.select { |weekday| @schedule.marked?(weekday) }

  def closed_weekdays = WorkingHour::WEEKDAYS.reject { |weekday| @schedule.marked?(weekday) }

  def toggle_id(weekday) = "working_hours_active_#{weekday}"

  def render_heading
    render Components::Owner::SettingsBackLink.new
    h1(class: "mt-2 text-xl font-extrabold tracking-tight text-ink") { TITLE }
    p(class: "text-sm text-ink-muted") { SUBTITLE }
  end

  def render_invite
    div(data: { invite: true }, class: INVITE_CLASS) { INVITE }
  end

  def render_closed_group
    return if closed_weekdays.empty?

    details(class: GROUP_CLASS, data: { closed_days: true }) do
      summary(class: SUMMARY_CLASS) do
        span(class: SUMMARY_NAMES_CLASS) { closed_days_sentence }
        span(class: SUMMARY_SUFFIX_CLASS) { CLOSED_SUFFIX }
      end
      div(class: GROUP_BODY_CLASS) do
        closed_weekdays.each { |weekday| render_day(weekday, first_open: false) }
      end
    end
  end

  def closed_days_sentence
    labels = closed_weekdays.map { |weekday| WorkingHour::WEEKDAY_LABELS[weekday] }
    [ labels.first, *labels.drop(1).map(&:downcase) ].to_sentence(words_connector: ", ", two_words_connector: " e ", last_word_connector: " e ")
  end

  def render_day(weekday, first_open:)
    section(data: { day: weekday }, class: "#{DAY_CLASS} #{@schedule.errors_for(weekday).any? ? 'border-danger' : 'border-line'}") do
      input(type: "checkbox", id: toggle_id(weekday), name: "working_hours[#{weekday}][active]", value: "1",
        checked: @schedule.marked?(weekday), class: "peer sr-only")
      render_header_row(weekday)
      render Components::Form::Errors.new(messages: @schedule.errors_for(weekday))
      div(class: FIELDS_CLASS) do
        render_hours_row(weekday)
        render_break_block(weekday)
        render_copy_button if first_open
      end
    end
  end

  def render_header_row(weekday)
    div(class: "flex items-center gap-3") do
      span(class: NAME_CLASS) { WorkingHour::WEEKDAY_LABELS[weekday] }
      label(for: toggle_id(weekday), class: TOGGLE_TRACK_CLASS) { span(class: TOGGLE_THUMB_CLASS) }
    end
  end

  def render_hours_row(weekday)
    div(class: ROW_CLASS) do
      render_time_field(weekday, "opens_at", hours_value(weekday, "opens_at", WeeklySchedule::DEFAULT_OPENS_AT), OPENS_LABEL, @schedule.hours_rejected?(weekday))
      span(class: JOINER_CLASS) { JOINER }
      render_time_field(weekday, "closes_at", hours_value(weekday, "closes_at", WeeklySchedule::DEFAULT_CLOSES_AT), CLOSES_LABEL, @schedule.hours_rejected?(weekday))
      div(class: SPACER_CLASS)
    end
  end

  def render_break_block(weekday)
    div(class: BREAK_CLASS, data: { break: true }) do
      span(class: BREAK_LABEL_CLASS) { BREAK_LABEL }
      div(class: ROW_CLASS) do
        render_time_field(weekday, "break_starts_at", @schedule.break_starts_at(weekday), BREAK_STARTS_LABEL, @schedule.break_rejected?(weekday))
        span(class: JOINER_CLASS) { JOINER }
        render_time_field(weekday, "break_ends_at", @schedule.break_ends_at(weekday), BREAK_ENDS_LABEL, @schedule.break_rejected?(weekday))
        render_remove_break_button
      end
    end
    render_add_break_button
  end

  def render_time_field(weekday, key, value, label_text, guilty)
    input(type: "time", name: "working_hours[#{weekday}][#{key}]", value: value, aria_label: label_text,
      step: WorkingHour::MINUTE_STEP * 60, data: { field: key },
      class: "#{FIELD_CLASS} #{guilty ? FIELD_GUILTY_BORDER : FIELD_BORDER}")
  end

  def render_remove_break_button
    button(type: "button", aria_label: REMOVE_BREAK_LABEL, class: REMOVE_CLASS, data: { action: "working-week#removeBreak" }) do
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.2", stroke_linecap: "round",
        stroke_linejoin: "round", aria_hidden: "true", class: "h-[17px] w-[17px] text-danger") { |icon| icon.path(d: "M5 12h14") }
    end
  end

  def render_add_break_button
    button(type: "button", class: "flex #{ADD_CLASS}", data: { add_break: true, action: "working-week#addBreak" }) do
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.4", stroke_linecap: "round",
        aria_hidden: "true", class: "h-[15px] w-[15px]") { |icon| icon.path(d: "M12 5v14M5 12h14") }
      plain ADD_BREAK_LABEL
    end
  end

  def render_copy_button
    button(type: "button", class: "flex #{COPY_CLASS}", data: { copy: true, action: "working-week#copyToAll" }) do
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.2", stroke_linecap: "round",
        stroke_linejoin: "round", aria_hidden: "true", class: "h-[15px] w-[15px]") do |icon|
        icon.rect(x: "9", y: "9", width: "11", height: "11", rx: "2")
        icon.path(d: "M15 5H6a2 2 0 0 0-2 2v9")
      end
      plain COPY_LABEL
    end
  end

  def hours_value(weekday, key, fallback)
    @schedule.marked?(weekday) ? @schedule.public_send(key, weekday).presence || fallback : fallback
  end
end
