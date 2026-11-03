class Components::LongDate < Components::Base
  WEEKDAY_NAMES = Appointment::Labels::WEEKDAY_NAMES
  MONTH_NAMES = Appointment::Labels::MONTH_NAMES

  def initialize(date:)
    @date = date
  end

  def view_template
    plain "#{WEEKDAY_NAMES[@date.wday]}, #{@date.day} de #{MONTH_NAMES[@date.month - 1]}"
  end
end
