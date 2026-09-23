class Components::Owner::Onboarding::Screen < Components::Base
  BACK_LABEL = "Voltar".freeze
  HEADER_CLASS = "flex items-center gap-3.5 px-6 pt-5 pb-3.5".freeze
  BACK_CLASS = "grid h-11 w-11 flex-none place-items-center rounded-full border border-line bg-surface".freeze
  BACK_ICON_CLASS = "h-5 w-5 text-ink".freeze
  GROUP_CLASS = "flex-grow text-sm font-bold text-ink-muted".freeze
  COUNTER_CLASS = "text-[13px] font-bold text-ink-subtle".freeze

  BAR_CLASS = "flex gap-1.5 px-6 pb-6".freeze
  SEGMENT_CLASS = "h-[5px] flex-grow rounded-full".freeze
  SEGMENT_FILLED_CLASS = "bg-brand-600".freeze
  SEGMENT_EMPTY_CLASS = "bg-line".freeze

  BODY_CLASS = "flex flex-grow flex-col gap-3.5 overflow-y-auto px-6".freeze

  FOOTER_CLASS = "px-6 pb-5 pt-3".freeze
  PRIMARY_CLASS = "min-h-13 w-full rounded-xl bg-brand-600 text-base font-extrabold text-on-brand".freeze
  SECONDARY_CLASS = "mt-2 min-h-10 w-full bg-none text-sm font-bold text-ink-muted".freeze

  def initialize(section:, group:, position:, primary:, total: 5, submit: false, secondary: nil, count: false, hidden: false)
    @section = section
    @group = group
    @position = position
    @total = total
    @primary = primary
    @submit = submit
    @secondary = secondary
    @count = count
    @hidden = hidden
  end

  def view_template
    section(class: "flex min-h-0 flex-grow flex-col", hidden: @hidden, data: section_data) do
      render_header
      render_bar
      div(class: BODY_CLASS) { yield }
      render_footer
    end
  end

  private

  def section_data
    { onboarding_target: "section", onboarding_section: @section }
  end

  def render_header
    div(class: HEADER_CLASS) do
      button(type: "button", class: BACK_CLASS, aria_label: BACK_LABEL, data: { onboarding_target: "back", action: "onboarding#back" }) { render_back_icon }
      span(class: GROUP_CLASS) { @group }
      span(class: COUNTER_CLASS) { "#{@position} de #{@total}" }
    end
  end

  def render_back_icon
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2.2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: BACK_ICON_CLASS) do |icon|
      icon.path(d: "m15 6-6 6 6 6")
    end
  end

  def render_bar
    div(class: BAR_CLASS, data: { progress_bar: true }) do
      @total.times { |index| div(class: "#{SEGMENT_CLASS} #{index < @position ? SEGMENT_FILLED_CLASS : SEGMENT_EMPTY_CLASS}") }
    end
  end

  def render_footer
    div(class: FOOTER_CLASS) do
      render_primary
      button(type: "button", class: SECONDARY_CLASS, data: { action: "onboarding#next" }) { @secondary } if @secondary
    end
  end

  def render_primary
    if @submit
      button(type: "submit", class: PRIMARY_CLASS) { @primary }
    else
      button(type: "button", class: PRIMARY_CLASS, data: primary_data) { @primary }
    end
  end

  def primary_data
    data = { action: "onboarding#next" }
    data[:onboarding_target] = "count" if @count
    data
  end
end
