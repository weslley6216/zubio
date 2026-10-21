class Client < ApplicationRecord
  PHONE_DIGITS = (10..11)
  COUNTRY_CODE = "55"
  PHONE_TAKEN_MESSAGE = "Este WhatsApp já está vinculado a outra conta Google.".freeze
  HANDOFF_PURPOSE = :client_handoff
  HANDOFF_WINDOW = 2.minutes

  acts_as_tenant :tenant

  before_validation :normalize_phone

  validates :name, presence: true
  validates :phone, length: { in: PHONE_DIGITS }
  validates_uniqueness_to_tenant :phone
  validates_uniqueness_to_tenant :google_uid, allow_nil: true

  generates_token_for HANDOFF_PURPOSE, expires_in: HANDOFF_WINDOW do
    [ handoff_generation ]
  end

  def self.find_by_handoff_token(token) = find_by_token_for(HANDOFF_PURPOSE, token)

  def handoff_token = generate_token_for(HANDOFF_PURPOSE)

  def consume_handoff_token! = increment!(:handoff_generation)

  def self.register(name:, phone:)
    client = find_or_initialize_by(phone: normalize(phone))
    client.name = name
    client.save
    client
  end

  def self.link_google!(uid:, email:, name:, phone:)
    normalized_phone = normalize(phone)
    client = find_by(google_uid: uid) || find_or_initialize_by(phone: normalized_phone)

    if client.persisted? && client.google_uid.present? && client.google_uid != uid
      conflicted = new(phone: normalized_phone)
      conflicted.errors.add(:phone, PHONE_TAKEN_MESSAGE)
      return conflicted
    end

    client.assign_attributes(name: name, email: email, google_uid: uid, account_linked_at: Time.current)
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

  def whatsapp_url = "https://wa.me/#{COUNTRY_CODE}#{phone}"

  def initials = name.split.first(2).map { |word| word[0] }.join.upcase

  def masked_email
    user, domain = email.split("@")
    "#{user[0]}***@#{domain}"
  end

  private

  def normalize_phone
    self.phone = self.class.normalize(phone)
  end
end
