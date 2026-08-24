class PagesController < ApplicationController
  skip_before_action :resolve_tenant
  before_action :resolve_tenant, unless: :platform_root_host?

  def home
    return redirect_to new_owner_session_path if ActsAsTenant.current_tenant

    render Views::Pages::Home.new(branding: Branding.platform_default)
  end

  private

  def platform_root_host? = platform_host?(request.host) && request.subdomains.empty?
end
