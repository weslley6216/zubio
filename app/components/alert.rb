class Components::Alert < Components::Base
  TONES = {
    success: { outline: "border-success", icon: "text-success", glyph: "m8 12 3 3 5-6" },
    danger: { outline: "border-danger", icon: "text-danger", glyph: "M12 8v4M12 16h.01" }
  }.freeze
  FRAME_CLASS = "flex items-center gap-2 rounded-md border bg-surface px-4 py-2 text-sm text-ink".freeze
  ICON_CLASS = "h-4 w-4 flex-none".freeze

  def initialize(text:, tone:)
    @text = text
    @tone = tone
  end

  def view_template
    tone = TONES.fetch(@tone)

    p(class: "#{FRAME_CLASS} #{tone.fetch(:outline)}", data: { alert: true }) do
      render_icon(tone)
      span { @text }
    end
  end

  private

  def render_icon(tone)
    svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", stroke_width: "2", stroke_linecap: "round",
      stroke_linejoin: "round", aria_hidden: "true", class: "#{ICON_CLASS} #{tone.fetch(:icon)}") do |icon|
      icon.circle(cx: "12", cy: "12", r: "9")
      icon.path(d: tone.fetch(:glyph))
    end
  end
end
