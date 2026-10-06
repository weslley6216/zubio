class Client < ApplicationRecord
  PHONE_DIGITS = (10..11)
  COUNTRY_CODE = "55"

  acts_as_tenant :tenant

  before_validation :normalize_phone

  validates :name, presence: true
  validates :phone, length: { in: PHONE_DIGITS }
  validates_uniqueness_to_tenant :phone

  def self.register(name:, phone:)
    client = find_or_initialize_by(phone: normalize(phone))
    client.name = name
    client.save
    client
  end

  def self.normalize(raw)
    digits = raw.to_s.gsub(/\D/, "")
    without_country = digits.delete_prefix(COUNTRY_CODE)
    return without_country if digits.start_with?(COUNTRY_CODE) && PHONE_DIGITS.include?(without_country.length)

    digits
  end

  private

  def normalize_phone
    self.phone = self.class.normalize(phone)
  end
end
