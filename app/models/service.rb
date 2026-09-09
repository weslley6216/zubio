class Service < ApplicationRecord
  acts_as_tenant(:tenant)
end
