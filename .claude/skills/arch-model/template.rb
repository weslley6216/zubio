class ChangeMe < ApplicationRecord
  acts_as_tenant :tenant

  MAX_SOMETHING = 10

  belongs_to :owner, class_name: "User", dependent: nil
  has_many :children, dependent: :destroy

  validates :name, presence: true
  validates :something_count, numericality: { less_than_or_equal_to: MAX_SOMETHING }

  scope :active, -> { where(active: true) }

  validate :cross_field_rule

  private

  def cross_field_rule
    return if valid_combination?

    errors.add(:base, :invalid_combination)
  end
end
