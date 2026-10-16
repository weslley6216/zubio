class WeeklySchedule
  include ActiveModel::Model

  DEFAULT_OPENS_AT = "09:00".freeze
  DEFAULT_CLOSES_AT = "18:00".freeze
  PARAM_KEYS = %i[active opens_at closes_at break_starts_at break_ends_at].freeze
  INVERTED_MESSAGE = "O fim precisa ser depois do início. Nada foi salvo.".freeze
  INCOMPLETE_BREAK_MESSAGE = "Preencha o começo e o fim do intervalo. Nada foi salvo.".freeze

  attr_accessor :professional, :days

  validate :days_follow_working_hour_rules

  def self.from_professional(professional)
    days = professional.working_hours.ordered.group_by(&:weekday).transform_values do |day_hours|
      slots = { "active" => "1", "opens_at" => day_hours.first.opens_at.strftime("%H:%M"), "closes_at" => day_hours.last.closes_at.strftime("%H:%M") }
      if day_hours.size > 1
        slots["break_starts_at"] = day_hours.first.closes_at.strftime("%H:%M")
        slots["break_ends_at"] = day_hours.last.opens_at.strftime("%H:%M")
      end
      slots
    end
    new(professional: professional, days: days.transform_keys(&:to_s))
  end

  def initialize(professional:, days: {})
    @professional = professional
    @days = (days || {}).to_h
  end

  def marked?(weekday) = @days.dig(weekday.to_s, "active").present?

  def any_marked? = WorkingHour::WEEKDAYS.any? { |weekday| marked?(weekday) }

  def opens_at(weekday) = value(weekday, "opens_at")

  def closes_at(weekday) = value(weekday, "closes_at")

  def break_starts_at(weekday) = value(weekday, "break_starts_at")

  def break_ends_at(weekday) = value(weekday, "break_ends_at")

  def break?(weekday) = break_starts_at(weekday).present? || break_ends_at(weekday).present?

  def errors_for(weekday) = errors[day_key(weekday)]

  def hours_rejected?(weekday) = rejected_fields[weekday] == :hours

  def break_rejected?(weekday) = rejected_fields[weekday] == :break

  def declaration
    active_weekdays.index_with { |weekday| WorkingHour.day_segments(opens_at(weekday), closes_at(weekday), break_starts_at(weekday), break_ends_at(weekday)) }
  end

  def save
    return false unless valid?

    professional.replace_working_hours!(declaration)
    true
  end

  private

  def active_weekdays = WorkingHour::WEEKDAYS.select { |weekday| marked?(weekday) }

  def value(weekday, key) = @days.dig(weekday.to_s, key).to_s

  def day_key(weekday) = :"day_#{weekday}"

  def rejected_fields = @rejected_fields ||= {}

  def days_follow_working_hour_rules
    active_weekdays.each { |weekday| validate_day(weekday) }
  end

  def validate_day(weekday)
    return reject(weekday, :break, INCOMPLETE_BREAK_MESSAGE) if break_half_filled?(weekday)

    case WorkingHour.break_violation(opens_at(weekday), closes_at(weekday), break_starts_at(weekday), break_ends_at(weekday))
    when WorkingHour::BREAK_OUT_OF_BOUNDS then return reject(weekday, :break, break_bounds_message(weekday))
    when WorkingHour::BREAK_INVERTED then return reject(weekday, :break, INVERTED_MESSAGE)
    end

    validate_segments(weekday)
  end

  def break_half_filled?(weekday) = break_starts_at(weekday).present? ^ break_ends_at(weekday).present?

  def validate_segments(weekday)
    WorkingHour.day_segments(opens_at(weekday), closes_at(weekday), break_starts_at(weekday), break_ends_at(weekday)).each do |from, to|
      candidate = WorkingHour.new(professional: professional, weekday: weekday, opens_at: from, closes_at: to)
      next if candidate.valid?

      candidate.errors.each do |error|
        next unless error.attribute.in?(%i[opens_at closes_at])
        next if error.type == :overlaps

        reject(weekday, :hours, error.type == :on_or_before_opening ? INVERTED_MESSAGE : error.message)
      end
    end
  end

  def reject(weekday, field, message)
    rejected_fields[weekday] ||= field
    errors.add(day_key(weekday), message) unless errors.added?(day_key(weekday), message)
  end

  def break_bounds_message(weekday) = "O intervalo precisa caber entre #{opens_at(weekday)} e #{closes_at(weekday)}. Nada foi salvo."
end
