class Components::Alert < Components::Base
  TONES = {
    success: "border-success-line bg-success-surface text-success",
    danger: "border-danger-line bg-danger-surface text-danger"
  }.freeze

  def initialize(text:, tone:)
    @text = text
    @tone = tone
  end

  def view_template
    p(class: "rounded-md border px-4 py-2 text-sm #{TONES.fetch(@tone)}", data: { alert: true }) { @text }
  end
end
