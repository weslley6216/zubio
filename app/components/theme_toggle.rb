class Components::ThemeToggle < Components::Base
  LABEL = "Trocar o tema".freeze

  # With a phone menu the toggle lives inside it, so the inline button stays a
  # tablet-and-up control; without one it is the only toggle and must always show.
  def initialize(hidden_on_phone:)
    @hidden_on_phone = hidden_on_phone
  end

  def view_template
    button(
      type: "button",
      class: "#{@hidden_on_phone ? "hidden sm:grid" : "grid"} h-11 w-11 cursor-pointer place-items-center rounded-lg border border-line bg-surface hover:bg-surface-2",
      title: LABEL,
      aria_label: LABEL,
      data: { action: "theme#toggle" }
    ) { render Components::ContrastMark.new }
  end
end
