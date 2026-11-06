class Branding::Palette
  extend StylesheetProducer

  BACKGROUNDS = %w[#16324A #F6EEF2 #1F4D3A #2B2B2B #F4F6F8].freeze
  ACCENTS = %w[#F0617A #8E4B6B #F2B33D #4FB3A9 #FFFFFF].freeze

  SUGGESTIONS = { brand_background: BACKGROUNDS, brand_600: ACCENTS }.freeze
  STARTING = { brand_background: "#16324A", brand_600: "#F0617A" }.freeze

  def self.swatches
    @swatches ||= (BACKGROUNDS + ACCENTS).uniq.freeze
  end

  def self.extras(_attribute) = []

  def self.stylesheet
    @stylesheet ||= swatches.map { |hex| %([data-swatch="#{hex}"]{background:#{hex};color:#{hex}}) }.join + preview_rules
  end

  def self.preview_rules
    BACKGROUNDS.map { |hex| %([data-preview-bg="#{hex}"]{#{Branding::Theme.background_variables(hex)}}) }.join +
      ACCENTS.map { |hex| %([data-preview-accent="#{hex}"]{#{Branding::Theme.accent_variables(hex)}}) }.join +
      %([data-preview-bg="none"]{#{Branding::Theme.background_variables(nil)}})
  end
end
