class Professional < ApplicationRecord
  belongs_to :user, optional: true

  acts_as_tenant(:tenant)

  validates :display_name, presence: true
end
