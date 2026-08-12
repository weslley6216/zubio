class PwaController < ApplicationController
  # Only service_worker trips Rails' cross-origin JS guard (blocks a .js
  # response from being embedded via <script src> on another origin) —
  # manifest is JSON and never triggers that check.
  skip_forgery_protection only: :service_worker

  BACKGROUND_COLOR = "#ffffff"
  DEFAULT_ICONS = [
    { src: "/icon.png", sizes: "512x512", type: "image/png", purpose: "any" },
    { src: "/icon.png", sizes: "512x512", type: "image/png", purpose: "maskable" }
  ].freeze

  def manifest
    tenant = ActsAsTenant.current_tenant
    branding = tenant.branding_or_default

    render json: tenant.manifest_identity.merge(
      theme_color: branding.brand_600,
      background_color: BACKGROUND_COLOR,
      icons: icons_for(branding)
    ), content_type: "application/manifest+json"
  end

  def service_worker
    render template: "pwa/service-worker", layout: false
  end

  private

  def icons_for(branding)
    variants = branding.icon_variants
    return DEFAULT_ICONS if variants.empty?

    variants.map do |icon|
      {
        src: rails_storage_proxy_path(icon[:variant]),
        sizes: icon[:sizes],
        type: "image/png",
        purpose: icon[:purpose]
      }
    end
  end
end
