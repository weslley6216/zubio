class Tenant < ApplicationRecord
  class OnboardingRejected < StandardError
    attr_reader :tenant, :branding, :services, :schedule

    def initialize(tenant:, branding:, services:, schedule:)
      @tenant = tenant
      @branding = branding
      @services = services
      @schedule = schedule
      super("onboarding rejected")
    end
  end

  RESERVED = %w[www api admin app assets cdn mail status help blog].freeze
  PLATFORM_HOST = Zubio::PLATFORM_HOST
  SUBDOMAIN_LENGTH = (3..63).freeze
  SUBDOMAIN_STATUS_PRIORITY = %i[blank too_short too_long invalid exclusion taken].freeze
  DOMAIN_FORMAT = /\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}\z/i
  NAME_MAX_LENGTH = 40
  DEFAULT_SUBDOMAIN_BASE = "estabelecimento".freeze
  PROVISIONAL_SUBDOMAIN_LENGTH = 12
  PROVISIONAL_MANIFEST_NAME = "Zubio".freeze

  has_one :branding, dependent: :destroy
  has_many :users, dependent: :restrict_with_error
  has_many :professionals, dependent: :restrict_with_error
  has_many :services, dependent: :restrict_with_error

  enum :status, { active: "active", suspended: "suspended" }

  validates :subdomain,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/ },
    length: { in: SUBDOMAIN_LENGTH },
    exclusion: { in: RESERVED }
  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }, if: :will_save_change_to_name?
  validates :custom_domain,
    format: { with: DOMAIN_FORMAT, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }
  validate :custom_domain_is_not_platform_host

  def cache_key_prefix
    "t/#{id}/#{branding&.updated_at&.to_i}"
  end

  def self.subdomain_status(subdomain)
    failures = subdomain_failures(subdomain)
    return :available if failures.empty?

    SUBDOMAIN_STATUS_PRIORITY.find { |status| failures.include?(status) } || :unknown
  end

  def self.subdomain_failures(subdomain)
    candidate = new(subdomain: subdomain)
    lookups, local = validators_on(:subdomain).partition { |validator| validator.is_a?(ActiveRecord::Validations::UniquenessValidator) }

    local.each { |validator| validator.validate(candidate) }
    lookups.each { |validator| validator.validate(candidate) } if candidate.errors[:subdomain].empty?

    candidate.errors.details[:subdomain].pluck(:error)
  end

  private_class_method :subdomain_failures

  def self.clamp_subdomain(subdomain) = subdomain.to_s.first(SUBDOMAIN_LENGTH.max + 1)

  def self.host_for(subdomain) = "#{subdomain}.#{PLATFORM_HOST}"

  def canonical_host
    custom_domain_verified_at? ? custom_domain : self.class.host_for(subdomain)
  end

  def branding_or_default
    branding || Branding.platform_default
  end

  def branded? = branding&.logo&.attached? || false

  def initial = name.presence&.first&.upcase

  def update_branding!(tenant_attrs:, branding_attrs:, remove_logo:)
    writes_branding = branding_attrs.present? || remove_logo
    logo_replaced = branding_attrs[:logo].present?

    transaction do
      update!(tenant_attrs)
      (branding || build_branding(brand_600: Branding::DEFAULT_BRAND_600)).update!(branding_attrs) if writes_branding
    end

    branding.logo.purge_later if remove_logo && !logo_replaced
    Branding::PrecomputeVariantsJob.perform_later(id) if logo_replaced
  end

  def self.provision_owner!(owner_attributes:)
    transaction do
      tenant = create!(subdomain: generate_provisional_subdomain)
      ActsAsTenant.with_tenant(tenant) do
        owner = tenant.users.create!(owner_attributes.merge(role: :owner))
        tenant.professionals.create!(display_name: owner.name, user: owner)
        owner
      end
    end
  end

  def self.generate_provisional_subdomain
    loop do
      candidate = SecureRandom.alphanumeric(PROVISIONAL_SUBDOMAIN_LENGTH).downcase
      return candidate if subdomain_status(candidate) == :available
    end
  end
  private_class_method :generate_provisional_subdomain

  def self.derive_subdomain(brand_name)
    base = subdomain_base(brand_name)
    candidate = base
    suffix = 1
    until subdomain_status(candidate) == :available
      suffix += 1
      candidate = suffixed_subdomain(base, suffix)
    end
    candidate
  end

  def self.subdomain_base(brand_name)
    slug = ActiveSupport::Inflector.transliterate(brand_name.to_s).downcase
      .gsub(/[^a-z0-9]+/, "-").delete_prefix("-").delete_suffix("-")
    slug.first(SUBDOMAIN_LENGTH.max).presence || DEFAULT_SUBDOMAIN_BASE
  end

  def self.suffixed_subdomain(base, suffix)
    tail = "-#{suffix}"
    "#{base.first(SUBDOMAIN_LENGTH.max - tail.length)}#{tail}"
  end
  private_class_method :subdomain_base, :suffixed_subdomain

  def onboarding_completed? = onboarding_completed_at.present?

  def complete_onboarding!(name:, branding_attrs:, services_attrs:, schedule:, professional:)
    assign_attributes(name: name, subdomain: self.class.derive_subdomain(name))
    new_branding = branding || build_branding(brand_600: Branding::DEFAULT_BRAND_600)
    new_branding.assign_attributes(branding_attrs) if branding_attrs.present?
    new_services = services_attrs.map { |service_attrs| Service.new(service_attrs) }
    new_schedule = Onboarding::Schedule.new(professional: professional, **schedule)

    reject_incomplete_onboarding(new_branding, new_services, new_schedule)

    transaction do
      save!
      new_branding.save!
      new_services.each(&:save!)
      professional.replace_weekly_hours!(**new_schedule.schedule_attributes)
      update!(onboarding_completed_at: Time.current)
    end
  end

  def manifest_identity
    display = name.presence || PROVISIONAL_MANIFEST_NAME

    {
      id: "/?tenant=#{subdomain}",
      name: display,
      short_name: display.truncate(12, omission: ""),
      start_url: "/",
      scope: "/",
      display: "standalone",
      orientation: "portrait",
      lang: "pt-BR"
    }
  end

  private

  def reject_incomplete_onboarding(new_branding, new_services, new_schedule)
    records = [ self, new_branding, *new_services, new_schedule ]
    return if records.map(&:valid?).all?

    raise OnboardingRejected.new(tenant: self, branding: new_branding, services: new_services, schedule: new_schedule)
  end

  def custom_domain_is_not_platform_host
    return if custom_domain.blank?

    normalized_domain = custom_domain.downcase
    normalized_platform_host = PLATFORM_HOST.downcase
    return unless normalized_domain == normalized_platform_host || normalized_domain.end_with?(".#{normalized_platform_host}")

    errors.add(:custom_domain, "não pode ser um subdomínio de #{PLATFORM_HOST}")
  end
end
