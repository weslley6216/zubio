class Owner::BrandColorTonesController < Owner::BaseController
  skip_before_action :enforce_onboarding_gate

  CACHE_WINDOW = 365.days
  ROLES = %w[brand_600 brand_background].freeze

  def show
    return head :not_found unless valid_role? && valid_background?

    tones = Branding::Tones.new(role: role.to_sym, background: background)

    if params[:hue].present?
      return head :not_found unless (hue = hue_param)

      respond_with_tones(options: tones.options(hue), selected: nil, advise: false)
    elsif params[:hex].present?
      return head :not_found unless (hex = hex_param)

      nearest = tones.nearest_valid(hex)
      hue = Branding::Tones.hue_of(hex)
      respond_with_tones(options: tones.options(hue), selected: nearest, advise: nearest != hex.upcase, hue: hue)
    else
      head :not_found
    end
  end

  def accent
    return head :not_found unless valid_background?
    return head :not_found if params[:selected].present? && selected_param.nil?

    suggestions = Branding::Palette.accent_suggestions(background: background)
    slot = selected_param && Branding::Palette::ACCENTS.index(selected_param.upcase)
    selected = slot && suggestions[slot]

    expires_in(CACHE_WINDOW, public: true)
    render Components::Form::AccentSwatches.new(tones: suggestions, selected: selected)
  end

  private

  def respond_with_tones(options:, selected:, advise:, hue: nil)
    expires_in(CACHE_WINDOW, public: true)
    render Components::Form::ColorTones.new(role: role, tones: options, selected: selected, advise: advise, hue: hue)
  end

  def valid_role? = ROLES.include?(params[:role])

  def role = params[:role]

  def valid_background? = params[:bg].blank? || params[:bg].match?(Branding::ColorScale::HEX)

  def background = params[:bg].presence

  def hue_param
    return Branding::Tones::NEUTRAL if params[:hue] == "neutral"
    return nil unless params[:hue].to_s.match?(/\A\d+\z/)

    value = params[:hue].to_i
    value if value.between?(0, 359)
  end

  def hex_param
    params[:hex] if params[:hex].to_s.match?(Branding::ColorScale::HEX)
  end

  def selected_param
    params[:selected] if params[:selected].to_s.match?(Branding::ColorScale::HEX)
  end
end
