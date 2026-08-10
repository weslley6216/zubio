class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  set_current_tenant_through_filter
  before_action :resolve_tenant

  private

  def resolve_tenant
    tenant = Tenant.active.find_by(subdomain: request.subdomains.first)
    return head :not_found if tenant.nil?

    set_current_tenant(tenant)
  end
end
