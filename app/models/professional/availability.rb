class Professional::Availability
  def initialize(professional:, service:, dates:)
    @professional = professional
    @dates = dates
    @duration = service.duration_minutes.minutes
  end

  def slots_by_date
    @dates.index_with { |date| slots_for(date) }
  end

  private

  def slots_for(date)
    open_windows(date)
      .flat_map { |window| candidates(window, @duration) }
      .select { |candidate| free?(candidate) && future?(candidate) }
  end

  def open_windows(date)
    exception = exceptions.find { |schedule_exception| schedule_exception.occurs_on == date }
    return exception_windows(date, exception) if exception

    working_hours.select { |working_hour| working_hour.weekday == date.wday }
      .map { |working_hour| [ at(date, working_hour.opens_at), at(date, working_hour.closes_at) ] }
  end

  def exception_windows(date, exception)
    return [] if exception.closed?

    [ [ at(date, exception.opens_at), at(date, exception.closes_at) ] ]
  end

  def candidates(window, duration)
    opening, closing = window
    slots = []
    candidate = opening
    while candidate + duration <= closing
      slots << candidate
      candidate += duration
    end
    slots
  end

  def free?(candidate)
    appointments.none? { |appointment| candidate < appointment.ends_at && appointment.starts_at < candidate + @duration }
  end

  def future?(candidate)
    candidate >= Time.current
  end

  def at(date, time_of_day)
    date.in_time_zone.change(hour: time_of_day.hour, min: time_of_day.min)
  end

  def working_hours
    @working_hours ||= @professional.working_hours.ordered.to_a
  end

  def exceptions
    @exceptions ||= @professional.schedule_exceptions.within(@dates.min..@dates.max).to_a
  end

  def appointments
    @appointments ||= @professional.appointments.occupying.within(window_range).to_a
  end

  def window_range
    @dates.min.in_time_zone.beginning_of_day..@dates.max.in_time_zone.end_of_day
  end
end
