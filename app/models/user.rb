class User < ApplicationRecord
  acts_as_tenant(:tenant)
  has_secure_password

  HANDOFF_PURPOSE = :owner_handoff
  HANDOFF_WINDOW = 2.minutes

  generates_token_for HANDOFF_PURPOSE, expires_in: HANDOFF_WINDOW do
    [ password_salt&.last(10), handoff_generation ]
  end

  def self.find_by_handoff_token(token) = find_by_token_for(HANDOFF_PURPOSE, token)

  def handoff_token = generate_token_for(HANDOFF_PURPOSE)

  def consume_handoff_token! = increment!(:handoff_generation)

  enum :role, { owner: "owner", admin: "admin", professional: "professional" }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates_uniqueness_to_tenant :email
  validates :name, presence: true
  validates :role, presence: true
end
