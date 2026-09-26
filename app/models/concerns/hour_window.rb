module HourWindow
  extend ActiveSupport::Concern

  MINUTE_STEP = 5

  included do
    validate :closes_after_opens
    validate :aligned_to_minute_step
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
end
