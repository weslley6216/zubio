class Branding < ApplicationRecord
  include StylesheetProducer

  acts_as_tenant :tenant

  has_one_attached :logo

  DEFAULT_BRAND_600 = "#4F46E5"
  DARK_ACCENT_STEP = 400
  NEUTRALS = {
    light: { "canvas" => "#f4f6f8", "surface" => "#ffffff", "surface-2" => "#f8fafb", "surface-3" => "#eef2f5" }.freeze,
    dark: { "canvas" => "#0b1117", "surface" => "#141e27", "surface-2" => "#18242e", "surface-3" => "#1f2c37" }.freeze
  }.freeze
  ON_NEUTRAL_STEPS = { light: [ 600, 700, 800, 900 ], dark: [ 400, 300, 200, 100, 50 ] }.freeze
  SOFT_STEP = { light: 50, dark: 900 }.freeze
  ON_SOFT_STEPS = { light: [ 700, 800, 900 ], dark: [ 300, 200, 100, 50 ] }.freeze
  ICON_SIZES = [ [ 192, "any" ], [ 512, "any" ], [ 512, "maskable" ] ].freeze
  HEADER_LOGO_LIMIT = [ 96, 96 ].freeze
  LOGO_CONTENT_TYPES = %w[image/png image/jpeg image/webp].freeze
  LOGO_MAX_BYTES = 5.megabytes
  INVALID_IMAGE_MESSAGE = "não é uma imagem válida".freeze
  CONTRAST_MESSAGE = "não tem contraste suficiente com o texto que vai sobre ela (mínimo 4.5:1)".freeze
  CUSTOM_COLOR_CHOICE = "custom".freeze

  validates :brand_600, presence: true, format: { with: ColorScale::HEX }
  validates :brand_secondary_600, format: { with: ColorScale::HEX }, allow_blank: true
  validate :brand_600_meets_contrast_minimum
  validate :brand_secondary_600_meets_contrast_minimum
  validate :logo_meets_upload_constraints

  def self.platform_default
    ActsAsTenant.without_tenant { new(brand_600: DEFAULT_BRAND_600) }
  end

  def self.resolve_color(choice, custom)
    (choice == CUSTOM_COLOR_CHOICE ? custom : choice).presence
  end

  def self.ramp_variables(prefix, scale)
    ramp = scale.tokens.map { |step, value| "--#{prefix}-#{step}:#{value};" }.join
    dark_accent = ColorScale.new(scale.tokens[DARK_ACCENT_STEP])
    roles = NEUTRALS.each_key.map { |theme| role_variables(prefix, scale, theme) }.join

    "#{ramp}--on-#{prefix}:#{scale.foreground};--on-#{prefix}-#{DARK_ACCENT_STEP}:#{dark_accent.foreground};#{roles}"
  end

  def self.role_variables(prefix, scale, theme)
    neutrals = NEUTRALS.fetch(theme).values
    soft_step = SOFT_STEP.fetch(theme)
    steps = {
      "ink" => scale.first_step_reaching(ColorScale::MIN_CONTRAST, steps: ON_NEUTRAL_STEPS.fetch(theme), against: neutrals),
      "mark" => scale.first_step_reaching(ColorScale::MIN_NON_TEXT_CONTRAST, steps: ON_NEUTRAL_STEPS.fetch(theme), against: neutrals),
      "soft" => soft_step,
      "soft-ink" => scale.first_step_reaching(ColorScale::MIN_CONTRAST, steps: ON_SOFT_STEPS.fetch(theme), against: [ scale.tokens.fetch(soft_step) ])
    }

    steps.map { |role, step| "--#{prefix}-#{role}-#{theme}:#{scale.tokens.fetch(step)};" }.join
  end

  def color_scale
    @color_scale ||= ColorScale.new(hex?(brand_600) ? brand_600 : DEFAULT_BRAND_600)
  end

  def css_variables
    self.class.ramp_variables("brand", color_scale) + self.class.ramp_variables("secondary", secondary_color_scale)
  end

  def stylesheet
    ":root{#{css_variables}}"
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

    supported_type = logo.blob.content_type.in?(LOGO_CONTENT_TYPES)
    within_size = logo.blob.byte_size <= LOGO_MAX_BYTES
    errors.add(:logo, "tipo de arquivo não suportado (use PNG, JPEG ou WEBP)") unless supported_type
    errors.add(:logo, "excede o tamanho máximo de 5MB") unless within_size
    errors.add(:logo, INVALID_IMAGE_MESSAGE) if supported_type && within_size && !logo_upload_decodes?
  end

  def logo_upload_decodes?
    change = attachment_changes["logo"]
    return true unless change

    Vips::Image.new_from_buffer(logo_upload_bytes(change.attachable), "", access: :sequential, fail_on: :error).avg
    true
  rescue Vips::Error
    false
  end

  def logo_upload_bytes(attachable)
    io = attachable.is_a?(Hash) ? attachable[:io] : attachable
    io.rewind
    io.read
  ensure
    io&.rewind
  end
end
