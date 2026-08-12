class Branding < ApplicationRecord
  acts_as_tenant :tenant

  has_one_attached :logo

  DEFAULT_BRAND_600 = "#4F46E5"
  ICON_SIZES = [ [ 192, "any" ], [ 512, "any" ], [ 512, "maskable" ] ].freeze
  LOGO_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  LOGO_MAX_BYTES = 5.megabytes

  validates :brand_600, presence: true, format: { with: ColorScale::HEX }
  validate :brand_600_meets_contrast_minimum
  validate :logo_meets_upload_constraints

  def self.platform_default
    new(brand_600: DEFAULT_BRAND_600)
  end

  def color_scale
    @color_scale ||= ColorScale.new(brand_600)
  end

  def css_variables
    ramp = color_scale.tokens.map { |step, value| "--brand-#{step}:#{value};" }.join

    "#{ramp}--on-brand:#{color_scale.foreground};"
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

  private

  def brand_600_meets_contrast_minimum
    return unless brand_600.present? && brand_600.match?(ColorScale::HEX)
    return if ColorScale.new(brand_600).contrast_against_white >= ColorScale::MIN_CONTRAST

    errors.add(:brand_600, "não tem contraste suficiente contra branco (mínimo 4.5:1)")
  end

  def logo_meets_upload_constraints
    return unless logo.attached?

    errors.add(:logo, "tipo de arquivo não suportado (use PNG, JPEG ou WEBP)") unless logo.blob.content_type.in?(LOGO_CONTENT_TYPES)
    errors.add(:logo, "excede o tamanho máximo de 5MB") if logo.blob.byte_size > LOGO_MAX_BYTES
  end
end
