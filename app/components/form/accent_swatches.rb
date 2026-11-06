class Components::Form::AccentSwatches < Components::Base
  include Phlex::Rails::Helpers::TurboFrameTag
  include Components::Form::Styles

  FRAME_ID = "accent-swatches".freeze
  OPTION_CLASS = "block".freeze
  FIELD_NAME = "branding[brand_600]".freeze

  def initialize(tones:, selected:)
    @tones = tones
    @selected = selected&.upcase
  end

  def view_template
    turbo_frame_tag(FRAME_ID, class: "contents") do
      link(rel: "stylesheet", href: swatch_stylesheet_path(colors: Branding::SwatchSheet.param(@tones)))
      @tones.zip(Branding::Palette::ACCENTS).each { |hex, accent| render_option(hex, accent) }
    end
  end

  private

  def render_option(hex, accent)
    label(class: OPTION_CLASS, data: { row_option: true }) do
      input(type: "radio", name: FIELD_NAME, value: hex, checked: hex == @selected, class: "peer sr-only", aria_label: hex,
        data: { accent: accent })
      span(class: SWATCH_CLASS, data: { swatch: hex })
    end
  end
end
