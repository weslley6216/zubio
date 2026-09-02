class PagesController < ApplicationController
  WWW_SUBDOMAIN = "www"

  skip_before_action :resolve_tenant
  before_action :redirect_www_to_apex, if: :www_host?
  before_action :resolve_tenant, unless: :platform_root_host?

  def home
    return redirect_to new_owner_session_path if ActsAsTenant.current_tenant

    render Views::Pages::Home.new(branding: Branding.platform_default, showcase_brands: Landing::ShowcaseBrand.all)
  end

  private

  def browser_restricted? = false

  def redirect_www_to_apex
    redirect_to root_url(host: Tenant::PLATFORM_HOST, params: request.query_parameters), status: :moved_permanently, allow_other_host: true
  end

  def www_host? = platform_host?(request.host) && request.subdomains == [ WWW_SUBDOMAIN ]

  def platform_root_host? = platform_host?(request.host) && request.subdomains.empty?
end
