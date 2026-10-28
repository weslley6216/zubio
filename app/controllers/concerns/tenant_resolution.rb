module TenantResolution
  extend ActiveSupport::Concern

  included do
    set_current_tenant_through_filter
    before_action :resolve_tenant
  end

  private

  def resolve_tenant
    tenant = if platform_host?(request.host)
      Tenant.active.find_by(subdomain: request.subdomains.first)
    else
      Tenant.active.where.not(custom_domain_verified_at: nil).find_by(custom_domain: request.host)
    end

    return head :not_found if tenant.nil?

    set_current_tenant(tenant)
  end

  def platform_host?(host) = Tenant.platform_host?(host)
end
