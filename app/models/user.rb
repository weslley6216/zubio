class User < ApplicationRecord
  acts_as_tenant(:tenant)
  has_secure_password

  enum :role, { owner: "owner", admin: "admin", professional: "professional" }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates_uniqueness_to_tenant :email
  validates :name, presence: true
  validates :role, presence: true
end
