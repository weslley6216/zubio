class Components::DayStripOverflow < Components::Base
  LAYOUTS = {
    sm: { gutter: "mx-7 sm:mx-3", arrow: "w-7 sm:hidden", backward: "left-0 justify-items-start", forward: "right-0 justify-items-end",
          icon: "h-6 w-6 text-(--theme-on-card)" },
    lg: { gutter: "mx-4 lg:mx-0", arrow: "w-12 lg:hidden", backward: "left-0 -ml-4 justify-items-start", forward: "right-0 -mr-4 justify-items-end",
          icon: "h-6 w-6 text-ink" }
  }.freeze
  SCROLLER_DATA = { day_strip_overflow_target: "scroller", action: "scroll->day-strip-overflow#update" }.freeze
  ARROW = "absolute inset-y-0 grid cursor-pointer items-center px-1".freeze
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
      class: [ ARROW, @layout.fetch(:arrow), @layout.fetch(direction), ("hidden" unless forward) ],
      data: { day_strip_overflow_target: direction.to_s, action: "day-strip-overflow##{direction}" }) do
      render Components::Icon.new(forward ? :chevron_right : :chevron_left, stroke_width: "2.2", class: @layout.fetch(:icon))
    end
  end
end
