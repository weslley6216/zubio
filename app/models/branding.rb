class Branding < ApplicationRecord
  acts_as_tenant :tenant

  has_one_attached :logo

  DEFAULT_BRAND_600 = "#4F46E5"
  ICON_SIZES = [ [ 192, "any" ], [ 512, "any" ], [ 512, "maskable" ] ].freeze

  validates :brand_600, presence: true, format: { with: ColorScale::HEX }
  validate :brand_600_meets_contrast_minimum

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

    errors.add(:brand_600, :insufficient_contrast)
  end
end
