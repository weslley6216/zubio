class Views::Owner::WorkingHours::Edit < Views::Base
  include Components::Form::Styles

  TITLE = "Horários da semana".freeze
  SUBTITLE = "Marque os dias em que você atende e as faixas de cada um.".freeze
  INVITE = "Você ainda não declarou seu expediente. Marque abaixo os dias em que atende.".freeze
  SUBMIT_LABEL = "Salvar horários".freeze
  BACK_LABEL = Components::Owner::Header::SETTINGS_LABEL
  BACK_ICON = "m15 6-6 6 6 6".freeze
  BACK_CLASS = "inline-flex min-h-11 items-center gap-1 text-sm font-bold text-ink-muted hover:text-ink".freeze

  DAY_CHIP_CLASS = "grid flex-1 cursor-pointer justify-items-center gap-0.5 rounded-xl border border-line bg-surface py-3 text-ink-subtle peer-checked:border-2 peer-checked:border-brand-600 peer-checked:bg-brand-soft peer-checked:font-extrabold peer-checked:text-brand-ink".freeze
  TOGGLE_LABEL_CLASS = "relative inline-flex h-11 w-[72px] flex-none cursor-pointer items-center justify-start rounded-full bg-line p-1 transition-colors peer-checked:justify-end peer-checked:bg-brand-600".freeze
  TOGGLE_THUMB_CLASS = "h-9 w-9 rounded-full bg-white shadow-sm".freeze

  def initialize(tenant:, branding:, schedule:, current_section:)
    @tenant = tenant
    @branding = branding
    @schedule = schedule
    @current_section = current_section
  end

  def view_template
    render Views::Layouts::Application.new(title: "#{TITLE} · #{@tenant.name}", branding: @branding) do
      render Components::Owner::Header.new(tenant: @tenant, branding: @branding, current_section: @current_section)
      main(class: Components::Owner::FormCard::PAGE_CLASS) do
        render_heading
        render_invite unless @schedule.any_marked?
        form_with(url: owner_working_hours_path, method: :patch, class: "mt-4 grid gap-3") do |form|
          WorkingHour::WEEKDAYS.each { |weekday| render_day(weekday) }
          form.submit(SUBMIT_LABEL, class: SUBMIT)
        end
      end
    end
  end

  private

  def toggle_id(weekday) = "working_hours_active_#{weekday}"

  def render_heading
    a(href: owner_settings_path, class: BACK_CLASS) do
      svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.5", stroke_linecap: "round",
        stroke_linejoin: "round", aria_hidden: "true", class: "h-4 w-4") { |icon| icon.path(d: BACK_ICON) }
      plain BACK_LABEL
    end
    h1(class: "mt-2 text-xl font-extrabold tracking-tight text-ink") { TITLE }
    p(class: "text-sm text-ink-muted") { SUBTITLE }
  end

  def render_day(weekday)
    section(data: { day: weekday }, class: "rounded-2xl border border-line bg-surface p-4") do
      input(type: "checkbox", id: toggle_id(weekday), name: "working_hours[#{weekday}][active]", value: "1",
        checked: @schedule.marked?(weekday), class: "peer sr-only")
      render_toggle_row(weekday)
      div(class: "mt-3 hidden gap-3 peer-checked:grid") do
        render_range(weekday, 0)
        render_range(weekday, 1)
      end
      render Components::Form::Errors.new(messages: @schedule.errors_for(weekday))
    end
  end

  def render_toggle_row(weekday)
    div(class: "flex items-center gap-3") do
      render_day_chip(weekday)
      render_toggle(weekday)
    end
  end

  def render_day_chip(weekday)
    label(for: toggle_id(weekday), class: DAY_CHIP_CLASS) do
      span(class: "text-[0.65rem] font-bold") { WorkingHour::WEEKDAY_NAMES[weekday].first(3).upcase }
      span(class: "text-xl font-extrabold leading-tight") { WorkingHour::WEEKDAY_NAMES[weekday].first(1) }
    end
  end

  def render_toggle(weekday)
    label(for: toggle_id(weekday), class: TOGGLE_LABEL_CLASS) { span(class: TOGGLE_THUMB_CLASS) }
  end

  def render_range(weekday, index)
    ranges = @schedule.ranges_for(weekday)[index]
    div(class: "grid grid-cols-2 gap-2") do
      input(type: "time", name: "working_hours[#{weekday}][opens_at_#{index}]", value: ranges[0],
        step: WorkingHour::MINUTE_STEP * 60, class: "min-h-11 #{Components::Form::Styles::CONTROL}")
      input(type: "time", name: "working_hours[#{weekday}][closes_at_#{index}]", value: ranges[1],
        step: WorkingHour::MINUTE_STEP * 60, class: "min-h-11 #{Components::Form::Styles::CONTROL}")
    end
  end

  def render_invite
    div(data: { invite: true }, class: "mt-3 rounded-lg border border-line bg-surface-2 p-3 text-sm text-ink-muted") { INVITE }
  end
end
