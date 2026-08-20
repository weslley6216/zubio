class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  set_current_tenant_through_filter
  before_action :resolve_tenant

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

  def platform_host?(host)
    host == Tenant::PLATFORM_HOST || host.end_with?(".#{Tenant::PLATFORM_HOST}")
  end

  def cache_key_prefix
    ActsAsTenant.current_tenant.cache_key_prefix
  end

  def current_branding
    ActsAsTenant.current_tenant.branding_or_default
  end
end
