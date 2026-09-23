class WorkingHour::Summary
  RANGE_SEPARATOR = "–".freeze
  DAY_SEPARATOR = ", ".freeze
  BAND_JOINER = " a ".freeze
  TIME_FORMAT = "%H:%M".freeze

  def initialize(working_hours)
    @working_hours = working_hours
  end

  def weekdays_label
    weekdays = @working_hours.map(&:weekday).uniq.sort
    return "" if weekdays.empty?
    return short_name(weekdays.first) if weekdays.one?

    if weekdays.last - weekdays.first + 1 == weekdays.length
      "#{short_name(weekdays.first)}#{BAND_JOINER}#{short_name(weekdays.last)}"
    else
      weekdays.map { |weekday| short_name(weekday) }.join(DAY_SEPARATOR)
    end
  end

  def hours_label
    return "" if @working_hours.empty?

    opens_at = @working_hours.map(&:opens_at).min
    closes_at = @working_hours.map(&:closes_at).max
    "#{format_time(opens_at)}#{RANGE_SEPARATOR}#{format_time(closes_at)}"
  end

  private

  def short_name(weekday) = WorkingHour::WEEKDAY_NAMES[weekday].first(3)

  def format_time(value) = value.strftime(TIME_FORMAT)
end
