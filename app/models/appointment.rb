class Appointment < ApplicationRecord
  belongs_to :professional
  belongs_to :service

  acts_as_tenant :tenant

  enum :status, { confirmed: "confirmed", cancelled: "cancelled" }

  before_validation :derive_ends_at

  scope :occupying, -> { where.not(status: :cancelled) }
  scope :within, ->(range) { where(starts_at: range) }
  scope :for_professional, ->(professional) { where(professional: professional) }

  private

  def derive_ends_at
    return unless starts_at.present? && service.present? && ends_at.blank?

    self.ends_at = starts_at + service.duration_minutes.minutes
  end
end
