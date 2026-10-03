class LoginLinksController < ApplicationController
  CONFIRMATION = "Se houver uma conta com esse e-mail, enviamos os links de acesso.".freeze

  skip_before_action :resolve_tenant, only: %i[new create]
  before_action :redirect_to_platform_host, unless: :platform_root_host?

  rate_limit to: 5, within: 1.hour, only: :create, name: "login_link",
    with: -> { redirect_to new_login_link_path, alert: "Muitas tentativas. Tente novamente mais tarde." }

  def new
    render Views::LoginLinks::New.new(branding: Branding.platform_default)
  end

  def create
    email = params[:email].to_s
    OwnerMailer.login_links(email).deliver_later if User.login_targets_for(email).any?

    redirect_to new_login_link_path, notice: CONFIRMATION
  end

  private

  def redirect_to_platform_host
    redirect_to new_login_link_url(host: Tenant::PLATFORM_HOST), allow_other_host: true
  end
end
