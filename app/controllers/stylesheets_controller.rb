class StylesheetsController < ApplicationController
  CACHE_WINDOW = 365.days

  skip_before_action :resolve_tenant
  before_action :resolve_tenant, only: :branding, unless: :platform_root_host?

  def branding
    serve(ActsAsTenant.current_tenant&.branding_or_default || Branding.platform_default)
  end

  def showcase
    serve(Landing::ShowcaseBrand)
  end

  private

  def browser_restricted? = false

  def serve(producer)
    apply_cache_policy(producer.stylesheet_digest)
    render plain: producer.stylesheet, content_type: "text/css"
  end

  def apply_cache_policy(digest)
    return expires_now unless params[:v] == digest

    expires_in(CACHE_WINDOW, public: true)
  end
end
