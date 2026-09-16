class Branding::Palette
  extend StylesheetProducer

  FAMILIES = %w[
    #4F46E5 #7E22CE #1E60C4 #0E7490 #14B8A6 #0B7658
    #EAB308 #B45309 #FF5A5F #BE123C #FF00BB #334155
  ].freeze

  SUGGESTIONS = {
    brand_600: %w[#4F46E5 #1E60C4 #0B7658 #BE123C #334155].freeze,
    brand_secondary_600: ([ "" ] + %w[#FF5A5F #B45309 #334155 #FF00BB]).freeze
  }.freeze

  def self.swatches
    @swatches ||= FAMILIES.flat_map { |hex| [ hex, Branding::ColorScale.new(hex).deepened_hex.upcase ] }.freeze
  end

  def self.stylesheet
    @stylesheet ||= swatches.map { |hex| %([data-swatch="#{hex}"]{background:#{hex}}) }.join + preview_rules
  end

  def self.preview_rules
    swatches.map do |hex|
      scale = Branding::ColorScale.new(hex)

      %([data-preview-brand="#{hex}"]{#{Branding.ramp_variables("brand", scale)}}) +
        %([data-preview-secondary="#{hex}"]{#{Branding.ramp_variables("secondary", scale)}})
    end.join + secondary_none_rule
  end

  def self.secondary_none_rule
    tokens = Branding.ramp_variables("secondary", Branding::ColorScale.new(Branding::DEFAULT_BRAND_600)).scan(/--([\w-]+):/).flatten
    body = tokens.map { |token| "--#{token}:var(--#{token.sub("secondary", "brand")});" }.join

    %([data-preview-secondary="none"]{#{body}})
  end
end
