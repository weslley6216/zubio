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

  def palette
    serve(Branding::Palette)
  end

  def preview
    sheet = Branding::PreviewSheet.new(brand: valid_hex(:brand), secondary: valid_hex(:secondary))
    return head :not_found if sheet.stylesheet.empty?

    expires_in(CACHE_WINDOW, public: true)
    render plain: sheet.stylesheet, content_type: "text/css"
  end

  private

  def browser_restricted? = false

  def valid_hex(param)
    value = params[param]
    value if value.to_s.match?(Branding::ColorScale::HEX)
  end

  def serve(producer)
    apply_cache_policy(producer.stylesheet_digest)
    render plain: producer.stylesheet, content_type: "text/css"
  end

  def apply_cache_policy(digest)
    return expires_now unless params[:v] == digest

    expires_in(CACHE_WINDOW, public: true)
  end
end
