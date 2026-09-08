class User < ApplicationRecord
  acts_as_tenant(:tenant)
  has_secure_password

  generates_token_for :owner_handoff, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  enum :role, { owner: "owner", admin: "admin", professional: "professional" }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates_uniqueness_to_tenant :email
  validates :name, presence: true
  validates :role, presence: true
end
