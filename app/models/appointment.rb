class Appointment < ApplicationRecord
  WINDOW_DAYS = 14

  belongs_to :professional
  belongs_to :service
  belongs_to :client

  acts_as_tenant :tenant

  has_secure_token :cancel_token

  enum :status, { confirmed: "confirmed", cancelled: "cancelled" }

  before_validation :derive_ends_at

  scope :occupying, -> { where.not(status: :cancelled) }
  scope :within, ->(range) { where(starts_at: range) }
  scope :for_professional, ->(professional) { where(professional: professional) }
  scope :for_day, ->(date) { within(date.in_time_zone.all_day).includes(:client, :service).order(:starts_at) }

  def self.booking_window = Date.current..(Date.current + (WINDOW_DAYS - 1))

  def self.book(professional:, service:, starts_at:, client_name:, client_phone:)
    return Result::Failure.new(:off_grid) unless offered?(professional, service, starts_at)

    client = nil
    appointment = transaction do
      client = Client.register(name: client_name, phone: client_phone)
      raise ActiveRecord::Rollback if client.errors.any?

      create!(professional: professional, service: service, client: client, starts_at: starts_at)
    end

    return Result::Failure.new(:invalid_client, record: client) if appointment.nil?

    Result::Success.new(appointment)
  rescue ActiveRecord::StatementInvalid => invalid
    raise unless invalid.cause.is_a?(PG::ExclusionViolation)

    Result::Failure.new(:taken)
  end

  def cancel!
    return unless cancellable?

    cancelled!
  end

  def cancellable? = confirmed? && !past?

  def visit_number = self.class.occupying.where(client_id: client_id, starts_at: ...starts_at).count + 1

  def past? = starts_at < Time.current

  def self.offered?(professional, service, starts_at)
    return false unless starts_at

    Professional::Availability.new(professional: professional, service: service, dates: starts_at.to_date..starts_at.to_date).offers?(starts_at)
  end
  private_class_method :offered?

  private

  def derive_ends_at
    return unless starts_at.present? && service.present? && ends_at.blank?

    self.ends_at = starts_at + service.duration_minutes.minutes
  end
end
