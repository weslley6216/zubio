class Professional < ApplicationRecord
  belongs_to :user, optional: true, dependent: nil
  has_many :working_hours, dependent: :destroy

  acts_as_tenant(:tenant)

  validates :display_name, presence: true
  validates :user_id, uniqueness: true, allow_nil: true

  def replace_working_hours!(declaration)
    transaction do
      working_hours.destroy_all
      declaration.each do |weekday, ranges|
        ranges.each { |opens_at, closes_at| working_hours.create!(weekday: weekday, opens_at: opens_at, closes_at: closes_at) }
      end
    end
  end

  def replace_weekly_hours!(weekdays:, opens_at:, closes_at:, break_starts_at: nil, break_ends_at: nil)
    segments = WorkingHour.day_segments(opens_at, closes_at, break_starts_at, break_ends_at)
    replace_working_hours!(weekdays.index_with { segments })
  end
end
