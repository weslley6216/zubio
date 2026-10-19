class Professional::Availability
  def initialize(professional:, service: nil, dates: nil)
    @professional = professional
    @dates = dates
    @duration = service.duration_minutes.minutes if service
  end

  def slots_by_date
    @dates.index_with { |date| slots_for(date) }
  end

  def taken_slots_by_date
    @dates.index_with { |date| taken_slots_for(date) }
  end

  def reasons_by_date
    @dates.index_with { |date| reason_for(date) }
  end

  def schedule_published?
    working_hours.any?
  end

  def appointments_outside_hours
    @dates ||= conflict_horizon
    future_appointments.reject { |appointment| within_hours?(appointment) }
  end

  def outside_hours(appointments)
    appointments.reject { |appointment| appointment.cancelled? || appointment.past? || within_hours?(appointment) }
  end

  def open_until(moment)
    @dates ||= moment.to_date..moment.to_date
    windows = open_windows(moment.to_date)
    return if windows.empty?

    opening = windows.map(&:first).min
    closing = windows.map(&:last).max
    closing if opening <= moment && moment < closing
  end

  def offers?(moment)
    return false unless moment

    future_candidates(moment.to_date).include?(moment)
  end

  def nearest_free(moment)
    @dates ||= moment.to_date..moment.to_date
    slots_for(moment.to_date).min_by { |slot| (slot - moment).abs }
  end

  private

  def future_appointments
    @future_appointments ||= @professional.appointments.occupying.where(starts_at: Time.current..).includes(:client).order(:starts_at).to_a
  end

  def within_hours?(appointment)
    open_windows(appointment.starts_at.to_date).any? do |opening, closing|
      opening <= appointment.starts_at && appointment.ends_at <= closing
    end
  end

  def conflict_horizon
    return Date.current..Date.current if future_appointments.empty?

    Date.current..future_appointments.last.starts_at.to_date
  end

  def slots_for(date)
    future_candidates(date).select { |candidate| free?(candidate) }
  end

  def taken_slots_for(date)
    future_candidates(date).reject { |candidate| free?(candidate) }
  end

  def future_candidates(date)
    open_windows(date)
      .flat_map { |window| candidates(window, @duration) }
      .select { |candidate| future?(candidate) }
  end

  def reason_for(date)
    if open_windows(date).any?
      slots_for(date).any? ? :bookable : :fully_booked
    elsif closed_exception?(date)
      :day_off
    else
      :no_working_day
    end
  end

  def closed_exception?(date)
    exceptions.any? { |schedule_exception| schedule_exception.occurs_on == date && schedule_exception.closed? }
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
