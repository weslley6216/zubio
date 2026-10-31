class Components::DayStripOverflow < Components::Base
  LAYOUTS = {
    sm: { gutter: "mx-4 sm:mx-0", arrow: "sm:hidden" },
    lg: { gutter: "mx-4 lg:mx-0", arrow: "lg:hidden" }
  }.freeze
  SCROLLER_DATA = { day_strip_overflow_target: "scroller", action: "scroll->day-strip-overflow#update" }.freeze
  ARROW = "absolute inset-y-0 grid w-12 cursor-pointer items-center px-1".freeze
  ARROW_BACKWARD = "left-0 -ml-4 justify-items-start".freeze
  ARROW_FORWARD = "right-0 -mr-4 justify-items-end".freeze
  ARROW_ICON = "h-6 w-6 text-ink".freeze
  BACKWARD_LABEL = "Dias anteriores".freeze
  FORWARD_LABEL = "Próximos dias".freeze

  def initialize(grid_from:)
    @layout = LAYOUTS.fetch(grid_from)
  end

  def gutter = @layout.fetch(:gutter)

  def view_template
    div(class: "relative", data: { controller: "day-strip-overflow" }) do
      yield(self)
      render_arrow(:backward)
      render_arrow(:forward)
    end
  end

  private

  def render_arrow(direction)
    forward = direction == :forward
    button(type: "button",
      aria_label: forward ? FORWARD_LABEL : BACKWARD_LABEL,
      class: [ ARROW, @layout.fetch(:arrow), (forward ? ARROW_FORWARD : ARROW_BACKWARD), ("hidden" unless forward) ],
      data: { day_strip_overflow_target: direction.to_s, action: "day-strip-overflow##{direction}" }) do
      render Components::Icon.new(forward ? :chevron_right : :chevron_left, stroke_width: "2.2", class: ARROW_ICON)
    end
  end
end
