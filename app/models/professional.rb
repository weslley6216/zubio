class Professional < ApplicationRecord
  belongs_to :user, optional: true, dependent: nil
  has_many :working_hours, dependent: :destroy

  acts_as_tenant(:tenant)

  validates :display_name, presence: true
  validates :user_id, uniqueness: true, allow_nil: true

  def replace_weekly_hours!(weekdays:, opens_at:, closes_at:, break_starts_at: nil, break_ends_at: nil)
    transaction do
      working_hours.destroy_all
      weekdays.each do |weekday|
        WorkingHour.day_segments(opens_at, closes_at, break_starts_at, break_ends_at).each do |from, to|
          working_hours.create!(weekday: weekday, opens_at: from, closes_at: to)
        end
      end
    end
  end
end
