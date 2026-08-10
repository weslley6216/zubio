class Professional < ApplicationRecord
  belongs_to :user, optional: true, dependent: nil

  acts_as_tenant(:tenant)

  validates :display_name, presence: true
  validates :user_id, uniqueness: true, allow_nil: true
end
