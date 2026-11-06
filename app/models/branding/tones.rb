class Branding::Tones
  LIGHTNESSES = [ 0.12, 0.22, 0.32, 0.42, 0.52, 0.62, 0.72, 0.82, 0.92 ].freeze
  SATURATIONS = [ 0.82, 0.42 ].freeze
  NEUTRAL = :neutral

  def self.hue_of(hex)
    scale = Branding::ColorScale.new(hex)
    scale.saturation.zero? ? NEUTRAL : scale.hue.round
  end

  def initialize(role:, background: nil)
    @role = role
    @background = background
  end

  def options(hue)
    candidates(hue).uniq.select { |hex| valid?(hex) }
  end

  def nearest_valid(hex)
    return hex.upcase if valid?(hex)

    target = Branding::ColorScale.new(hex).luminance

    options(self.class.hue_of(hex)).min_by { |candidate| (Branding::ColorScale.new(candidate).luminance - target).abs }
  end

  def valid?(hex)
    text_legible?(hex) && (role != :brand_600 || stands_out?(hex))
  end

  def text_legible?(hex)
    Branding::ColorScale.new(hex).contrast_against_foreground >= Branding::ColorScale::MIN_CONTRAST
  end

  def stands_out?(hex)
    Branding::Theme.new(background: background.presence, accent: hex).accent_stands_out?
  end

  private

  attr_reader :role, :background

  def candidates(hue)
    if hue == NEUTRAL
      LIGHTNESSES.map { |lightness| Branding::ColorScale.from_hsl(0, 0.0, lightness).upcase }
    else
      SATURATIONS.product(LIGHTNESSES).map { |saturation, lightness| Branding::ColorScale.from_hsl(hue, saturation, lightness).upcase }
    end
  end
end
