class Views::Owner::WorkingHours::Edit < Views::Base
  include Components::Form::Styles

  TITLE = "Horários da semana".freeze
  SUBTITLE = "Marque os dias em que você atende e as faixas de cada um.".freeze
  INVITE = "Você ainda não declarou seu expediente. Marque abaixo os dias em que atende.".freeze
  SUBMIT_LABEL = "Salvar horários".freeze

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
        h1(class: "text-xl font-extrabold tracking-tight text-ink") { TITLE }
        p(class: "text-sm text-ink-muted") { SUBTITLE }
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

  def render_day(weekday)
    section(data: { day: weekday }, class: "rounded-2xl border border-line bg-surface p-4") do
      input(type: "checkbox", id: toggle_id(weekday), name: "working_hours[#{weekday}][active]", value: "1",
        checked: @schedule.marked?(weekday), class: "peer sr-only")
      label(for: toggle_id(weekday), class: "flex min-h-11 cursor-pointer items-center") { WorkingHour::WEEKDAY_NAMES[weekday] }
      div(class: "mt-3 hidden gap-3 peer-checked:grid") do
        render_range(weekday, 0)
        render_range(weekday, 1)
      end
      render Components::Form::Errors.new(messages: @schedule.errors_for(weekday))
    end
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
