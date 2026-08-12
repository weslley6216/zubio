class Tenant < ApplicationRecord
  RESERVED = %w[www api admin app assets cdn mail status help blog].freeze

  has_one :branding, dependent: :destroy

  enum :status, { active: "active", suspended: "suspended" }

  validates :subdomain,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: /\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/ },
    length: { in: 3..63 },
    exclusion: { in: RESERVED }
  validates :name, presence: true

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
end
