class Service::Price
  CURRENCY = "R$".freeze
  CENTS_PER_REAL = 100
  CENTS_DIGITS = 2
  THOUSANDS_DELIMITER = ".".freeze
  DECIMAL_SEPARATOR = ",".freeze
  BLANK_EDGES = /\A[[:space:]]+|[[:space:]]+\z/
  CURRENCY_PREFIX = /\A#{Regexp.escape(CURRENCY)}[[:space:]]*/
  BRAZILIAN_FORMAT = /\A(?<reais>\d{1,3}(?:\.\d{3})+|\d+)(?:,(?<fraction>\d{1,2}))?\z/
  DOT_DECIMAL_FORMAT = /\A(?<reais>\d+)\.(?<fraction>\d{1,2})\z/
  UNPRICED_LABEL = "Sob consulta".freeze

  attr_reader :cents

  def self.parse(text)
    amount = text.to_s.gsub(BLANK_EDGES, "").sub(CURRENCY_PREFIX, "")
    match = BRAZILIAN_FORMAT.match(amount) || DOT_DECIMAL_FORMAT.match(amount)
    return unless match

    reais = match[:reais].delete(THOUSANDS_DELIMITER).to_i
    fraction = match[:fraction].to_s.ljust(CENTS_DIGITS, "0").to_i

    new(reais * CENTS_PER_REAL + fraction)
  end

  def self.label(cents)
    cents ? new(cents).with_currency : UNPRICED_LABEL
  end

  def initialize(cents)
    @cents = cents
  end

  def to_s
    reais, fraction = cents.divmod(CENTS_PER_REAL)

    "#{ActiveSupport::NumberHelper.number_to_delimited(reais, delimiter: THOUSANDS_DELIMITER)}#{DECIMAL_SEPARATOR}#{fraction.to_s.rjust(CENTS_DIGITS, "0")}"
  end

  def with_currency = "#{CURRENCY} #{self}"
end
