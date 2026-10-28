class ApplicationController < ActionController::Base
  allow_browser versions: :modern, if: :browser_restricted?

  stale_when_importmap_changes

  layout false

  include TenantResolution

  private

  def browser_restricted? = true

  def platform_root_host? = Tenant.platform_root_host?(request)

  def cache_key_prefix
    ActsAsTenant.current_tenant.cache_key_prefix
  end

  def current_branding
    ActsAsTenant.current_tenant.branding_or_default
  end
end
