class Tenant < ApplicationRecord
  RESERVED = %w[www api admin app assets cdn mail status help blog].freeze
  PLATFORM_HOST = Zubio::PLATFORM_HOST
  SUBDOMAIN_LENGTH = (3..63).freeze
  SUBDOMAIN_STATUS_PRIORITY = %i[blank too_short too_long invalid exclusion taken].freeze
  DOMAIN_FORMAT = /\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}\z/i

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
  validates :name, presence: true
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

  def update_branding!(tenant_attrs:, branding_attrs:, remove_logo:)
    target_branding = branding || build_branding
    logo_replaced = branding_attrs[:logo].present?

    transaction do
      update!(tenant_attrs)
      target_branding.update!(branding_attrs)
    end

    target_branding.logo.purge_later if remove_logo && !logo_replaced
    Branding::PrecomputeVariantsJob.perform_later(id) if logo_replaced
  end

  def self.provision_owner!(tenant_attributes:, owner_attributes:)
    transaction do
      tenant = create!(tenant_attributes)
      ActsAsTenant.with_tenant(tenant) do
        owner = tenant.users.create!(owner_attributes.merge(role: :owner))
        tenant.professionals.create!(display_name: owner.name, user: owner)
        owner
      end
    end
  end

  def manifest_identity
    {
      id: "/?tenant=#{subdomain}",
      name: name,
      short_name: name.truncate(12, omission: ""),
      start_url: "/",
      scope: "/",
      display: "standalone",
      orientation: "portrait",
      lang: "pt-BR"
    }
  end

  private

  def custom_domain_is_not_platform_host
    return if custom_domain.blank?

    normalized_domain = custom_domain.downcase
    normalized_platform_host = PLATFORM_HOST.downcase
    return unless normalized_domain == normalized_platform_host || normalized_domain.end_with?(".#{normalized_platform_host}")

    errors.add(:custom_domain, "não pode ser um subdomínio de #{PLATFORM_HOST}")
  end
end
