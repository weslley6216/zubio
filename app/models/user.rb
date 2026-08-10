class User < ApplicationRecord
  acts_as_tenant(:tenant)

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates_uniqueness_to_tenant :email
  validates :name, presence: true
end
