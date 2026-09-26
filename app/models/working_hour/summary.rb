class WorkingHour::Summary
  RANGE_SEPARATOR = "–".freeze
  DAY_SEPARATOR = ", ".freeze
  BAND_JOINER = " a ".freeze
  TIME_FORMAT = "%H:%M".freeze
  NO_HOURS = "Nenhum horário definido".freeze
  ATTENDANCE_SINGULAR = "1 dia de atendimento".freeze
  ATTENDANCE_PLURAL = "%<count>d dias de atendimento".freeze

  def initialize(working_hours)
    @working_hours = working_hours
  end

  def line
    return NO_HOURS if @working_hours.empty?
    return "#{weekdays_label}, #{hours_label}" if uniform_hours?

    count = @working_hours.map(&:weekday).uniq.length
    count == 1 ? ATTENDANCE_SINGULAR : format(ATTENDANCE_PLURAL, count: count)
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

  def uniform_hours?
    envelopes = @working_hours.group_by(&:weekday).values.map do |day_hours|
      [ day_hours.map(&:opens_at).min, day_hours.map(&:closes_at).max ]
    end
    envelopes.uniq.length == 1
  end
end
