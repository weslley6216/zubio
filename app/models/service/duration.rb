class Service::Duration
  MINUTES_PER_HOUR = 60
  HOURS_UNIT = "h".freeze
  MINUTES_UNIT = "min".freeze

  def self.label(minutes)
    hours, rest = minutes.divmod(MINUTES_PER_HOUR)
    parts = []
    parts << "#{hours} #{HOURS_UNIT}" if hours.positive?
    parts << "#{rest} #{MINUTES_UNIT}" if rest.positive?
    parts.join(" ")
  end
end
