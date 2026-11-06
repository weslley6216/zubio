class Branding::SwatchSheet
  MAX_COLORS = 24
  SEPARATOR = "-".freeze
  DIGITS = /\A\h{6}\z/

  def self.param(hexes) = hexes.map { |hex| hex.delete_prefix("#").upcase }.join(SEPARATOR)

  def initialize(colors)
    @colors = colors.to_s.split(SEPARATOR).first(MAX_COLORS)
  end

  def stylesheet
    @colors.grep(DIGITS).map { |digits| rule("##{digits.upcase}") }.join
  end

  private

  def rule(hex) = %([data-swatch="#{hex}"]{background:#{hex};color:#{hex}})
end
