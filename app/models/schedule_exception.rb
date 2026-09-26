class ScheduleException < ApplicationRecord
  include HourWindow

  belongs_to :professional
  acts_as_tenant :tenant

  normalizes :reason, with: ->(reason) { reason.strip.presence }

  validates :occurs_on, presence: true
  validate :window_matches_closed_state

  private

  def window_matches_closed_state
    if closed?
      errors.add(:opens_at, :window_on_closed_day) if opens_at.present? || closes_at.present?
    elsif opens_at.blank? || closes_at.blank?
      errors.add(:opens_at, :window_required)
    end
  end
end
