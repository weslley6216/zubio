class PagesController < ApplicationController
  skip_before_action :resolve_tenant
  before_action :redirect_www_to_apex, if: :www_host?

  def home
    render Views::Pages::Home.new(branding: Branding.platform_default, showcase_brands: Landing::ShowcaseBrand.all)
  end

  private

  def browser_restricted? = false

  def redirect_www_to_apex
    redirect_to root_url(host: Tenant::PLATFORM_HOST, params: request.query_parameters), status: :moved_permanently, allow_other_host: true
  end

  def www_host? = Tenant.www_host?(request)
end
