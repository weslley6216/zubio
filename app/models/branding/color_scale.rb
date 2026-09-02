class Branding::ColorScale
  HEX = /\A#[0-9a-fA-F]{6}\z/
  MIN_CONTRAST = 4.5
  WHITE = "#ffffff"
  DARK_NEUTRAL = "#111827"

  attr_reader :hex

  def initialize(hex)
    raise ArgumentError, "invalid brand_600: #{hex.inspect}" unless hex.is_a?(String) && hex.match?(HEX)

    @hex = hex
  end

  def foreground
    contrast_ratio(luminance, self.class.luminance_of(WHITE)) >=
      contrast_ratio(luminance, self.class.luminance_of(DARK_NEUTRAL)) ? WHITE : DARK_NEUTRAL
  end

  def contrast_against_white
    contrast_against(self.class.new(WHITE))
  end

  def contrast_against(other)
    contrast_ratio(luminance, other.luminance)
  end

  def self.luminance_of(hex)
    new(hex).luminance
  end

  def luminance
    r, g, b = rgb
    0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
  end

  LIGHTNESS_BY_STEP = {
    50 => 0.97, 100 => 0.94, 200 => 0.86, 300 => 0.76, 400 => 0.66,
    500 => 0.56, 700 => 0.42, 800 => 0.32, 900 => 0.22
  }.freeze

  def tokens
    steps = LIGHTNESS_BY_STEP.transform_values { |lightness| hex_at_lightness(lightness) }
    steps[600] = hex
    steps.sort.to_h
  end

  private

  def hex_at_lightness(lightness)
    hue, saturation, = to_hsl
    from_hsl(hue, saturation, lightness)
  end

  def to_hsl
    r, g, b = rgb
    max = [ r, g, b ].max
    min = [ r, g, b ].min
    delta = max - min
    lightness = (max + min) / 2.0
    saturation = delta.zero? ? 0.0 : delta / (1 - (2 * lightness - 1).abs)

    hue =
      if delta.zero?
        0.0
      elsif max == r
        60 * (((g - b) / delta) % 6)
      elsif max == g
        60 * (((b - r) / delta) + 2)
      else
        60 * (((r - g) / delta) + 4)
      end

    [ hue, saturation, lightness ]
  end

  def from_hsl(hue, saturation, lightness)
    c = (1 - (2 * lightness - 1).abs) * saturation
    x = c * (1 - ((hue / 60.0) % 2 - 1).abs)
    m = lightness - c / 2.0

    r, g, b =
      case hue
      when 0...60 then [ c, x, 0 ]
      when 60...120 then [ x, c, 0 ]
      when 120...180 then [ 0, c, x ]
      when 180...240 then [ 0, x, c ]
      when 240...300 then [ x, 0, c ]
      else [ c, 0, x ]
      end

    [ r, g, b ]
      .map { |channel| ((channel + m) * 255).round.clamp(0, 255) }
      .map { |value| value.to_s(16).rjust(2, "0") }
      .then { |parts| "##{parts.join}" }
  end

  def rgb
    hex.delete("#").scan(/../).map { |channel| channel.to_i(16) / 255.0 }
  end

  def linearize(channel)
    channel <= 0.03928 ? channel / 12.92 : (((channel + 0.055) / 1.055)**2.4)
  end

  def contrast_ratio(luminance_a, luminance_b)
    lighter, darker = [ luminance_a, luminance_b ].max, [ luminance_a, luminance_b ].min
    (lighter + 0.05) / (darker + 0.05)
  end
end
