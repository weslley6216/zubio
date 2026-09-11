class Branding::Palette
  FAMILIES = %w[
    #4F46E5 #7E22CE #1E60C4 #0E7490 #14B8A6 #0B7658
    #EAB308 #B45309 #FF5A5F #BE123C #FF00BB #334155
  ].freeze

  def self.swatches
    @swatches ||= FAMILIES.flat_map { |hex| [ hex, Branding::ColorScale.new(hex).deepened_hex.upcase ] }.freeze
  end

  def self.stylesheet
    @stylesheet ||= swatches.map { |hex| %([data-swatch="#{hex}"]{background:#{hex}}) }.join
  end

  def self.stylesheet_digest
    @stylesheet_digest ||= Digest::SHA256.hexdigest(stylesheet).first(Branding::DIGEST_LENGTH)
  end
end
