class Components::Alert < Components::Base
  TONES = {
    success: { outline: "border-success", color: "text-success", icon: :circle_check },
    danger: { outline: "border-danger", color: "text-danger", icon: :circle_alert },
    neutral: { outline: "border-line", color: "text-ink-muted", icon: :info }
  }.freeze
  FRAME_CLASS = "flex items-start gap-2 rounded-md border bg-surface px-4 py-2 text-sm text-ink".freeze
  ICON_CLASS = "h-4 w-4 flex-none".freeze

  def initialize(text: nil, tone:)
    @text = text
    @tone = tone
  end

  def view_template(&block)
    tone = TONES.fetch(@tone)

    div(class: "#{FRAME_CLASS} #{tone.fetch(:outline)}", data: { alert: true }) do
      render Components::Icon.new(tone.fetch(:icon), class: "#{ICON_CLASS} #{tone.fetch(:color)}")
      block ? yield : span { @text }
    end
  end
end
