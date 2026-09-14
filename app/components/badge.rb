class Components::Badge < Components::Base
  TONES = {
    accent: "bg-brand-accent text-on-brand-accent",
    muted: "bg-surface-3 text-ink-muted"
  }.freeze

  BASE_CLASS = "justify-self-start rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wide".freeze

  def initialize(text:, tone:)
    @text = text
    @tone = tone
  end

  def view_template
    span(class: "#{BASE_CLASS} #{TONES.fetch(@tone)}") { @text }
  end
end
