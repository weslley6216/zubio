class Appointment::Labels
  WEEKDAY_ABBR = %w[DOM SEG TER QUA QUI SEX SÁB].freeze
  WEEKDAY_NAMES = %w[Domingo Segunda Terça Quarta Quinta Sexta Sábado].freeze
  MONTH_ABBR = %w[jan fev mar abr mai jun jul ago set out nov dez].freeze
  MONTH_NAMES = %w[janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro].freeze

  def self.day_label(date)
    "#{WEEKDAY_ABBR[date.wday].capitalize}, #{date.day} #{MONTH_ABBR[date.month - 1]}"
  end

  def initialize(appointment)
    @appointment = appointment
  end

  def when_label
    "#{self.class.day_label(@appointment.starts_at.to_date)} · #{@appointment.starts_at.strftime("%H:%M")}"
  end

  def duration_label
    "#{::Service::Duration.minutes_label(@appointment.service.duration_minutes)} · termina #{@appointment.ends_at.strftime("%H:%M")}"
  end

  def price_label
    ::Service::Price.label(@appointment.service.public_price_cents)
  end
end
