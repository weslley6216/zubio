class WorkingHour < ApplicationRecord
  MINUTE_STEP = 5
  WEEKDAYS = (0..6).to_a.freeze
  WEEKDAY_NAMES = %w[Domingo Segunda-feira Terça-feira Quarta-feira Quinta-feira Sexta-feira Sábado].freeze

  belongs_to :professional
  acts_as_tenant :tenant

  validates :weekday, presence: true, inclusion: { in: WEEKDAYS }
  validates :opens_at, :closes_at, presence: true
  validate :closes_after_opens
  validate :aligned_to_minute_step
  validate :within_professional_day

  scope :for_weekday, ->(weekday) { where(weekday: weekday) }
  scope :ordered, -> { order(:weekday, :opens_at) }

  def weekday_name
    WEEKDAY_NAMES[weekday] if weekday.in?(WEEKDAYS)
  end

  private

  def closes_after_opens
    return if opens_at.blank? || closes_at.blank?

    errors.add(:closes_at, :on_or_before_opening) if closes_at <= opens_at
  end

  def aligned_to_minute_step
    [ :opens_at, :closes_at ].each do |field|
      value = public_send(field)
      next if value.blank?

      errors.add(field, :off_step) unless value.sec.zero? && (value.min % MINUTE_STEP).zero?
    end
  end

  def within_professional_day
    return if professional.blank? || opens_at.blank? || closes_at.blank? || !weekday.in?(WEEKDAYS)

    siblings = professional.working_hours.for_weekday(weekday)
    siblings = siblings.where.not(id: id) if persisted?

    errors.add(:opens_at, :overlaps) if siblings.any? { |sibling| opens_at < sibling.closes_at && sibling.opens_at < closes_at }
  end
end
