class Session < ApplicationRecord
  acts_as_tenant(:tenant)

  belongs_to :user
end
