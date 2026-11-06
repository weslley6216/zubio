class Components::Form::AccentSwatches < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag
  include Components::Form::Styles

  FRAME_ID = "accent-swatches".freeze
  ROW_CLASS = "flex flex-wrap gap-2.5".freeze
  OPTION_CLASS = "block".freeze
  FIELD_NAME = "branding[brand_600]".freeze

  def initialize(tones:, selected:)
    @tones = tones
    @selected = selected&.upcase
  end

  def view_template
    turbo_frame_tag(FRAME_ID) do
      div(class: ROW_CLASS, data: { swatch_row: true }) { @tones.each { |hex| render_option(hex) } }
    end
  end

  private

  def render_option(hex)
    label(class: OPTION_CLASS, data: { row_option: true }) do
      input(type: "radio", name: FIELD_NAME, value: hex, checked: hex == @selected, class: "peer sr-only", aria_label: hex)
      span(class: SWATCH_CLASS, data: { swatch: hex })
    end
  end
end
