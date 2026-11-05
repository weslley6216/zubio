class Branding::Theme
  STEP = 5
  MUTED_FROM = 78
  TINT_SHARE = 14
  GHOST_FROM = 35
  DANGER_LINE_SHARE = 50
  CARD_LINE_SHARE = 12
  CARD_CHIP_SHARE = 65
  FIELD_LINE_FROM = 20
  CARD_STEP = 100
  DANGER = "#b42318".freeze
  DANGER_ON_DARK = "#ffb4be".freeze

  def self.background_variables(hex) = new(background: hex, accent: nil).background_css

  def self.accent_variables(hex) = new(background: nil, accent: hex).accent_css

  def initialize(background:, accent:)
    @background = background
    @accent = accent
  end

  def background
    @background || Branding::NEUTRALS.fetch(:light).fetch("surface-2")
  end

  def tokens
    @tokens ||= build_tokens.freeze
  end

  def background_css
    theme_variables(background_tokens)
  end

  def accent_css
    theme_variables(accent_tokens)
  end

  def css_variables
    theme_variables(tokens)
  end

  def accent_stands_out?
    accent_scale.contrast_against(Branding::ColorScale.new(background)) >= Branding::ColorScale::MIN_NON_TEXT_CONTRAST
  end

  private

  attr_reader :accent

  def theme_variables(hash)
    hash.map { |name, value| "--theme-#{name}:#{value};" }.join
  end

  def background_scale
    @background_scale ||= Branding::ColorScale.new(background)
  end

  def accent_scale
    @accent_scale ||= Branding::ColorScale.new(accent)
  end

  def dark_background?
    background_scale.foreground == Branding::ColorScale::WHITE
  end

  def build_tokens
    background_tokens.merge(accent_tokens).merge(cross_tokens)
  end

  def background_tokens
    @background_tokens ||= begin
      bg = background
      on_bg = background_scale.foreground
      card = dark_background? ? background_scale.tokens[CARD_STEP] : Branding::ColorScale::WHITE
      on_card = Branding::ColorScale.new(card).foreground

      on_bg_muted = climb(on_bg, over: bg, from: MUTED_FROM, minimum: Branding::ColorScale::MIN_CONTRAST)
      ghost = climb(on_bg, over: bg, from: GHOST_FROM, minimum: Branding::ColorScale::MIN_NON_TEXT_CONTRAST)
      danger_on_bg =
        if dark_background?
          climb(Branding::ColorScale::WHITE, over: DANGER_ON_DARK, from: 0, minimum: Branding::ColorScale::MIN_CONTRAST, against: bg)
        else
          climb(Branding::ColorScale::DARK_NEUTRAL, over: DANGER, from: 0, minimum: Branding::ColorScale::MIN_CONTRAST, against: bg)
        end
      on_card_muted = climb(on_card, over: card, from: MUTED_FROM, minimum: Branding::ColorScale::MIN_CONTRAST)
      field_line = climb(on_card, over: card, from: FIELD_LINE_FROM, minimum: Branding::ColorScale::MIN_NON_TEXT_CONTRAST)
      danger_on_card = climb(Branding::ColorScale::DARK_NEUTRAL, over: DANGER, from: 0, minimum: Branding::ColorScale::MIN_CONTRAST, against: card)

      {
        "bg" => bg,
        "on-bg" => on_bg,
        "on-bg-muted" => on_bg_muted,
        "bg-tint" => mix(on_bg, over: bg, share: TINT_SHARE),
        "ghost" => ghost,
        "danger-on-bg" => danger_on_bg,
        "danger-line-on-bg" => mix(danger_on_bg, over: bg, share: DANGER_LINE_SHARE),
        "card" => card,
        "on-card" => on_card,
        "on-card-muted" => on_card_muted,
        "card-line" => mix(on_card, over: card, share: CARD_LINE_SHARE),
        "card-chip" => mix(Branding::ColorScale::WHITE, over: card, share: CARD_CHIP_SHARE),
        "field-line" => field_line,
        "danger-on-card" => danger_on_card
      }
    end
  end

  def accent_tokens
    @accent_tokens ||= { "accent" => accent, "on-accent" => accent_scale.foreground }
  end

  def cross_tokens
    return {} unless accent

    card = background_tokens.fetch("card")
    on_card = background_tokens.fetch("on-card")
    tokens = { "focus" => focus(bg: background_tokens.fetch("bg"), card: card, on_card: on_card) }
    tokens["selected-ring"] = on_card if accent_scale.contrast_against(Branding::ColorScale.new(card)) < Branding::ColorScale::MIN_NON_TEXT_CONTRAST

    tokens
  end

  def climb(color, over:, from:, minimum:, against: over)
    from.step(100, STEP) do |share|
      candidate = mix(color, over: over, share: share)
      return candidate if Branding::ColorScale.new(candidate).contrast_against(Branding::ColorScale.new(against)) >= minimum
    end

    color
  end

  def mix(color, over:, share:)
    Branding::ColorScale.new(color).mix(over, share)
  end

  def focus(bg:, card:, on_card:)
    [ bg, accent, on_card ].find do |candidate|
      Branding::ColorScale.new(candidate).contrast_against(Branding::ColorScale.new(card)) >= Branding::ColorScale::MIN_NON_TEXT_CONTRAST
    end
  end
end
