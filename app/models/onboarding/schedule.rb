class Onboarding::Schedule
  include ActiveModel::Model

  NO_WEEKDAY_MESSAGE = "marque ao menos um dia".freeze
  BREAK_INVERTED_MESSAGE = "o intervalo precisa terminar depois de começar".freeze

  attr_accessor :professional, :weekdays, :opens_at, :closes_at, :break_starts_at, :break_ends_at

  validate :at_least_one_weekday
  validate :hours_follow_working_hour_rules
  validate :break_ends_after_it_starts

  def marked?(weekday) = Array(weekdays).include?(weekday)

  def schedule_attributes
    { weekdays: weekdays, opens_at: opens_at, closes_at: closes_at, break_starts_at: break_starts_at, break_ends_at: break_ends_at }
  end

  private

  def at_least_one_weekday
    errors.add(:weekdays, NO_WEEKDAY_MESSAGE) if weekdays.blank?
  end

  def hours_follow_working_hour_rules
    return if weekdays.blank?

    WorkingHour.day_segments(opens_at, closes_at, break_starts_at, break_ends_at).each do |from, to|
      candidate = WorkingHour.new(professional: professional, weekday: WorkingHour::WEEKDAYS.first, opens_at: from, closes_at: to)
      next if candidate.valid?

      candidate.errors.each { |error| errors.add(error.attribute, error.message) unless errors.added?(error.attribute, error.message) }
    end
  end

  def break_ends_after_it_starts
    starts, ends = [ break_starts_at, break_ends_at ].map { |value| ActiveModel::Type::Time.new.cast(value) }
    return if starts.nil? || ends.nil?

    errors.add(:break_ends_at, BREAK_INVERTED_MESSAGE) if ends <= starts
  end
end
