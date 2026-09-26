class WeeklySchedule
  include ActiveModel::Model

  DAY_PARAM_KEYS = %i[active opens_at_0 closes_at_0 opens_at_1 closes_at_1].freeze
  NO_RANGE_MESSAGE = "marque ao menos uma faixa neste dia".freeze
  INCOMPLETE_RANGE_MESSAGE = "informe abertura e fechamento".freeze
  OVERLAP_MESSAGE = "as faixas deste dia se sobrepõem".freeze

  attr_accessor :professional, :days

  validate :days_follow_working_hour_rules

  def self.from_professional(professional)
    days = professional.working_hours.ordered.group_by(&:weekday).transform_values do |day_hours|
      ranges = day_hours.map { |working_hour| [ working_hour.opens_at, working_hour.closes_at ] }
      slots = { "active" => "1" }
      ranges.first(2).each_with_index do |(opens_at, closes_at), index|
        slots["opens_at_#{index}"] = opens_at.strftime("%H:%M")
        slots["closes_at_#{index}"] = closes_at.strftime("%H:%M")
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

  def ranges_for(weekday)
    [ 0, 1 ].map { |index| [ value(weekday, "opens_at_#{index}"), value(weekday, "closes_at_#{index}") ] }
  end

  def errors_for(weekday) = errors[day_key(weekday)]

  def declaration
    active_weekdays.index_with { |weekday| complete_ranges(weekday) }
  end

  def save
    return false unless valid?

    professional.replace_working_hours!(declaration)
    true
  end

  private

  def active_weekdays = WorkingHour::WEEKDAYS.select { |weekday| marked?(weekday) }

  def value(weekday, key) = @days.dig(weekday.to_s, key).to_s

  def raw_ranges(weekday)
    ranges_for(weekday).reject { |opens_at, closes_at| opens_at.blank? && closes_at.blank? }
  end

  def complete_ranges(weekday)
    raw_ranges(weekday).select { |opens_at, closes_at| opens_at.present? && closes_at.present? }
  end

  def day_key(weekday) = :"day_#{weekday}"

  def days_follow_working_hour_rules
    active_weekdays.each do |weekday|
      ranges = raw_ranges(weekday)
      next errors.add(day_key(weekday), NO_RANGE_MESSAGE) if ranges.empty?

      validate_each_range(weekday, ranges)
      errors.add(day_key(weekday), OVERLAP_MESSAGE) if overlapping?(weekday)
    end
  end

  def validate_each_range(weekday, ranges)
    ranges.each do |opens_at, closes_at|
      next errors.add(day_key(weekday), INCOMPLETE_RANGE_MESSAGE) if opens_at.blank? || closes_at.blank?

      candidate = WorkingHour.new(professional: professional, weekday: weekday, opens_at: opens_at, closes_at: closes_at)
      candidate.valid?
      candidate.errors.each do |error|
        next unless error.attribute.in?(%i[opens_at closes_at])
        next if error.type == :overlaps

        errors.add(day_key(weekday), error.message) unless errors.added?(day_key(weekday), error.message)
      end
    end
  end

  def overlapping?(weekday)
    complete = complete_ranges(weekday).sort_by(&:first)
    complete.each_cons(2).any? { |(_, earlier_closes), (later_opens, _)| later_opens < earlier_closes }
  end
end
