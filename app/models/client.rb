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

  def phone_display
    local = phone.length == 11 ? "#{phone[2, 5]}-#{phone[7, 4]}" : "#{phone[2, 4]}-#{phone[6, 4]}"
    "(#{phone[0, 2]}) #{local}"
  end

  def tel_href = "tel:+#{COUNTRY_CODE}#{phone}"

  private

  def normalize_phone
    self.phone = self.class.normalize(phone)
  end
end
