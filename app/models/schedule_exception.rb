class ScheduleException < ApplicationRecord
  include HourWindow

  belongs_to :professional
  acts_as_tenant :tenant

  validates :occurs_on, presence: true
end
