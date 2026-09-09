class Service < ApplicationRecord
  acts_as_tenant(:tenant)

  MIN_DURATION_MINUTES = 5
  MAX_DURATION_MINUTES = 480
  DURATION_STEP_MINUTES = 5
  DURATION_CHOICES = (MIN_DURATION_MINUTES..MAX_DURATION_MINUTES).step(DURATION_STEP_MINUTES).to_a.freeze

  validates :name, presence: true
  validates_uniqueness_to_tenant :name
  validates :duration_minutes, inclusion: { in: DURATION_CHOICES }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(Arel.sql(%(name COLLATE "und-x-icu"))) }

  def price = price_cents.to_d / 100
end
