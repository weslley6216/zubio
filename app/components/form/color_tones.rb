class Components::Form::ColorTones < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag
  include Components::Form::Styles

  ADVICE_MESSAGE = "Ajustamos o tom para um que combina com o fundo escolhido.".freeze
  ROW_CLASS = "flex flex-wrap gap-2.5".freeze
  OPTION_CLASS = "block".freeze
  ADVICE_CLASS = "text-[12px] text-ink-muted".freeze

  def initialize(role:, tones:, selected:, advise: false)
    @role = role
    @tones = tones
    @selected = selected&.upcase
    @advise = advise
  end

  def view_template
    turbo_frame_tag(frame_id) do
      div(class: ROW_CLASS, data: { tone_row: true }) { @tones.each { |hex| render_tone(hex) } }
      p(class: ADVICE_CLASS, data: { tone_advice: true }) { ADVICE_MESSAGE } if @advise
    end
  end

  private

  def frame_id = "tones-#{@role}"

  def render_tone(hex)
    label(class: OPTION_CLASS, data: { row_option: true }) do
      input(type: "radio", name: "tone-#{@role}", value: hex, checked: hex == @selected, class: "peer sr-only", aria_label: hex,
        data: { tone: hex })
      span(class: SWATCH_CLASS, data: { swatch: hex })
    end
  end
end
