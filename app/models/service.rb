class Service < ApplicationRecord
  acts_as_tenant(:tenant)

  MIN_DURATION_MINUTES = 5
  MAX_DURATION_MINUTES = 480
  DURATION_STEP_MINUTES = 5
  DURATION_CHOICES = (MIN_DURATION_MINUTES..MAX_DURATION_MINUTES).step(DURATION_STEP_MINUTES).to_a.freeze
  NAME_MAX_LENGTH = 100
  DESCRIPTION_MAX_LENGTH = 500
  MAX_PRICE_CENTS = 9_999_999

  NAME_REQUIRED_MESSAGE = "informe o nome do serviço".freeze
  NAME_TOO_LONG_MESSAGE = "use no máximo #{NAME_MAX_LENGTH} caracteres".freeze
  NAME_TAKEN_MESSAGE = "já existe um serviço com este nome".freeze
  DESCRIPTION_TOO_LONG_MESSAGE = "use no máximo #{DESCRIPTION_MAX_LENGTH} caracteres".freeze
  DURATION_NOT_WHOLE_MESSAGE = "informe a duração em minutos inteiros".freeze
  DURATION_OUT_OF_STEP_MESSAGE = "escolha um múltiplo de #{DURATION_STEP_MINUTES} entre #{MIN_DURATION_MINUTES} e #{MAX_DURATION_MINUTES} minutos".freeze
  PRICE_REQUIRED_MESSAGE = "informe o preço".freeze
  PRICE_OUT_OF_RANGE_MESSAGE = "use um valor entre #{Price.new(0).with_currency} e #{Price.new(MAX_PRICE_CENTS).with_currency}".freeze

  normalizes :name, with: ->(name) { name.squish }
  normalizes :description, with: ->(description) { description.strip.presence }

  validates :name,
    presence: { message: NAME_REQUIRED_MESSAGE },
    length: { maximum: NAME_MAX_LENGTH, message: NAME_TOO_LONG_MESSAGE }
  validates_uniqueness_to_tenant :name, message: NAME_TAKEN_MESSAGE
  validates :description, length: { maximum: DESCRIPTION_MAX_LENGTH, message: DESCRIPTION_TOO_LONG_MESSAGE }
  validates :duration_minutes,
    numericality: { only_integer: true, message: DURATION_NOT_WHOLE_MESSAGE },
    inclusion: { in: DURATION_CHOICES, message: DURATION_OUT_OF_STEP_MESSAGE }
  validates :price_cents, presence: { message: PRICE_REQUIRED_MESSAGE }
  validates :price_cents,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_PRICE_CENTS, message: PRICE_OUT_OF_RANGE_MESSAGE },
    allow_nil: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(Arel.sql(%(name COLLATE "und-x-icu"))) }

  def price = price_cents.to_d / 100
end
