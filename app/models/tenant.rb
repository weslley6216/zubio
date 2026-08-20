class Tenant < ApplicationRecord
  RESERVED = %w[www api admin app assets cdn mail status help blog].freeze
  PLATFORM_HOST = ENV.fetch("APP_HOST", "zubio.com.br")
  CUSTOM_DOMAIN_FALLBACK_TARGET = ENV.fetch("CLOUDFLARE_FALLBACK_ORIGIN", "fallback.zubio.com.br")
  DOMAIN_FORMAT = /\A(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}\z/i

  has_one :branding, dependent: :destroy
  has_many :users

  enum :status, { active: "active", suspended: "suspended" }

  validates :subdomain,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/ },
    length: { in: 3..63 },
    exclusion: { in: RESERVED }
  validates :name, presence: true
  validates :custom_domain,
    format: { with: DOMAIN_FORMAT, allow_blank: true },
    uniqueness: { case_sensitive: false, allow_blank: true }
  validate :custom_domain_is_not_platform_host

  scope :pending_custom_domain_verification, -> { where.not(custom_domain: nil).where(custom_domain_verified_at: nil) }

  def cache_key_prefix
    "t/#{id}/#{branding&.updated_at&.to_i}"
  end

  def branding_or_default
    branding || Branding.platform_default
  end

  def update_branding!(tenant_attrs:, branding_attrs:, remove_logo:)
    target_branding = branding || build_branding
    logo_replaced = branding_attrs[:logo].present?

    transaction do
      update!(tenant_attrs)
      target_branding.update!(branding_attrs)
    end

    target_branding.logo.purge_later if remove_logo && !logo_replaced
    Branding::PrecomputeIconVariantsJob.perform_later(id) if logo_replaced
  end

  def register_custom_domain!(domain)
    self.custom_domain = domain
    raise ActiveRecord::RecordInvalid, self unless valid?

    hostname = CloudflareCustomHostname.new.create(domain)

    update!(
      custom_domain_cloudflare_id: hostname.id,
      custom_domain_verification_txt_name: hostname.verification_txt_name,
      custom_domain_verification_txt_value: hostname.verification_txt_value,
      custom_domain_verified_at: nil
    )

    Tenant::CheckCustomDomainVerificationJob.perform_later(id)
  end

  def remove_custom_domain!
    CloudflareCustomHostname.new.delete(custom_domain_cloudflare_id) if custom_domain_cloudflare_id.present?

    update!(
      custom_domain: nil,
      custom_domain_cloudflare_id: nil,
      custom_domain_verification_txt_name: nil,
      custom_domain_verification_txt_value: nil,
      custom_domain_verified_at: nil
    )
  end

  def check_custom_domain_verification!
    return if custom_domain.blank? || custom_domain_verified_at.present?

    update!(custom_domain_verified_at: Time.current) if CloudflareCustomHostname.new.status(custom_domain_cloudflare_id) == "active"
  end

  def self.provision!(tenant_attributes:, owner_attributes:)
    transaction do
      tenant = create!(tenant_attributes)
      ActsAsTenant.with_tenant(tenant) { tenant.users.create!(owner_attributes.merge(role: :owner)) }
      tenant
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
    return unless custom_domain == PLATFORM_HOST || custom_domain.end_with?(".#{PLATFORM_HOST}")

    errors.add(:custom_domain, "não pode ser um subdomínio de #{PLATFORM_HOST}")
  end
end
