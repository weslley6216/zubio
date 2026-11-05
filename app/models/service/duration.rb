class Service::Duration
  MINUTES_PER_HOUR = 60
  HOURS_UNIT = "h".freeze
  MINUTES_UNIT = "min".freeze
  COMPACT_HOURS = "%<hours>dh".freeze
  COMPACT_HOURS_AND_MINUTES = "%<hours>dh%<minutes>02d".freeze

  def self.compact_label(minutes)
    hours, rest = minutes.divmod(MINUTES_PER_HOUR)
    return minutes_label(minutes) if hours.zero?
    return format(COMPACT_HOURS, hours: hours) if rest.zero?

    format(COMPACT_HOURS_AND_MINUTES, hours: hours, minutes: rest)
  end

  def self.minutes_label(minutes)
    "#{minutes} #{MINUTES_UNIT}"
  end

  def self.label(minutes)
    hours, rest = minutes.divmod(MINUTES_PER_HOUR)
    parts = []
    parts << "#{hours} #{HOURS_UNIT}" if hours.positive?
    parts << "#{rest} #{MINUTES_UNIT}" if rest.positive?
    parts.join(" ")
  end
end
