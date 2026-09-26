class WorkingHour < ApplicationRecord
  include HourWindow

  WEEKDAYS = (0..6).to_a.freeze
  WEEKDAY_NAMES = %w[Domingo Segunda-feira Terça-feira Quarta-feira Quinta-feira Sexta-feira Sábado].freeze

  belongs_to :professional
  acts_as_tenant :tenant

  validates :weekday, presence: true, inclusion: { in: WEEKDAYS }
  validates :opens_at, :closes_at, presence: true
  validate :within_professional_day

  scope :for_weekday, ->(weekday) { where(weekday: weekday) }
  scope :ordered, -> { order(:weekday, :opens_at) }

  def self.day_segments(opens_at, closes_at, break_starts_at, break_ends_at)
    return [ [ opens_at, closes_at ] ] if break_starts_at.blank? || break_ends_at.blank?

    [ [ opens_at, break_starts_at ], [ break_ends_at, closes_at ] ]
  end

  private

  def within_professional_day
    return if professional.blank? || opens_at.blank? || closes_at.blank? || !weekday.in?(WEEKDAYS)

    siblings = professional.working_hours.for_weekday(weekday)
    siblings = siblings.where.not(id: id) if persisted?

    errors.add(:opens_at, :overlaps) if siblings.any? { |sibling| opens_at < sibling.closes_at && sibling.opens_at < closes_at }
  end
end
