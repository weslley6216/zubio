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

  validates :brand_600, presence: true, format: { with: ColorScale::HEX }
  validate :brand_600_meets_contrast_minimum
  validate :logo_meets_upload_constraints

  def self.platform_default
    ActsAsTenant.without_tenant { new(brand_600: DEFAULT_BRAND_600) }
  end

  def color_scale
    @color_scale ||= ColorScale.new(valid_hex_brand_600? ? brand_600 : DEFAULT_BRAND_600)
  end

  def css_variables
    ramp = color_scale.tokens.map { |step, value| "--brand-#{step}:#{value};" }.join

    "#{ramp}--on-brand:#{color_scale.foreground};--on-brand-400:#{dark_accent_scale.foreground};"
  end

  def stylesheet
    ":root{#{css_variables}}"
  end

  def stylesheet_digest
    Digest::SHA256.hexdigest(stylesheet).first(DIGEST_LENGTH)
  end

  def dark_accent_scale
    @dark_accent_scale ||= ColorScale.new(color_scale.tokens[DARK_ACCENT_STEP])
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

  def valid_hex_brand_600?
    brand_600.present? && brand_600.match?(ColorScale::HEX)
  end

  def brand_600_meets_contrast_minimum
    return unless valid_hex_brand_600?
    return if ColorScale.new(brand_600).contrast_against_foreground >= ColorScale::MIN_CONTRAST

    errors.add(:brand_600, "não tem contraste suficiente com o texto que vai sobre ela (mínimo 4.5:1)")
  end

  def logo_meets_upload_constraints
    return unless logo.attached?

    errors.add(:logo, "tipo de arquivo não suportado (use PNG, JPEG ou WEBP)") unless logo.blob.content_type.in?(LOGO_CONTENT_TYPES)
    errors.add(:logo, "excede o tamanho máximo de 5MB") if logo.blob.byte_size > LOGO_MAX_BYTES
  end
end
