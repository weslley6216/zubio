class Branding < ApplicationRecord
  acts_as_tenant :tenant

  has_one_attached :logo

  DEFAULT_BRAND_600 = "#4F46E5"
  DARK_ACCENT_STEP = 400
  ICON_SIZES = [ [ 192, "any" ], [ 512, "any" ], [ 512, "maskable" ] ].freeze
  HEADER_LOGO_LIMIT = [ 96, 96 ].freeze
  LOGO_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  LOGO_MAX_BYTES = 5.megabytes
  DIGEST_LENGTH = 16
  CONTRAST_MESSAGE = "não tem contraste suficiente com o texto que vai sobre ela (mínimo 4.5:1)".freeze

  validates :brand_600, presence: true, format: { with: ColorScale::HEX }
  validates :brand_secondary_600, format: { with: ColorScale::HEX }, allow_blank: true
  validate :brand_600_meets_contrast_minimum
  validate :brand_secondary_600_meets_contrast_minimum
  validate :logo_meets_upload_constraints

  def self.platform_default
    ActsAsTenant.without_tenant { new(brand_600: DEFAULT_BRAND_600) }
  end

  def color_scale
    @color_scale ||= ColorScale.new(hex?(brand_600) ? brand_600 : DEFAULT_BRAND_600)
  end

  def css_variables
    ramp_variables("brand", color_scale) + ramp_variables("secondary", secondary_color_scale)
  end

  def stylesheet
    ":root{#{css_variables}}"
  end

  def stylesheet_digest
    Digest::SHA256.hexdigest(stylesheet).first(DIGEST_LENGTH)
  end

  def icon_variants
    return [] unless logo.attached?

    ICON_SIZES.map do |size, purpose|
      {
        variant: logo.variant(resize_to_fill: [ size, size ], format: :png),
        sizes: "#{size}x#{size}",
        purpose: purpose
      }
    end
  end

  def header_logo
    return unless logo.attached? && logo.blob.persisted?

    logo.variant(resize_to_limit: HEADER_LOGO_LIMIT, format: :png)
  end

  private

  def hex?(value) = value.present? && value.match?(ColorScale::HEX)

  def secondary_color_scale
    @secondary_color_scale ||= hex?(brand_secondary_600) ? ColorScale.new(brand_secondary_600) : color_scale
  end

  def ramp_variables(prefix, scale)
    ramp = scale.tokens.map { |step, value| "--#{prefix}-#{step}:#{value};" }.join
    dark_accent = ColorScale.new(scale.tokens[DARK_ACCENT_STEP])

    "#{ramp}--on-#{prefix}:#{scale.foreground};--on-#{prefix}-#{DARK_ACCENT_STEP}:#{dark_accent.foreground};"
  end

  def brand_600_meets_contrast_minimum = validate_contrast(:brand_600)

  def brand_secondary_600_meets_contrast_minimum = validate_contrast(:brand_secondary_600)

  def validate_contrast(attribute)
    value = public_send(attribute)
    return unless hex?(value)
    return if ColorScale.new(value).contrast_against_foreground >= ColorScale::MIN_CONTRAST

    errors.add(attribute, CONTRAST_MESSAGE)
  end

  def logo_meets_upload_constraints
    return unless logo.attached?

    errors.add(:logo, "tipo de arquivo não suportado (use PNG, JPEG ou WEBP)") unless logo.blob.content_type.in?(LOGO_CONTENT_TYPES)
    errors.add(:logo, "excede o tamanho máximo de 5MB") if logo.blob.byte_size > LOGO_MAX_BYTES
  end
end
