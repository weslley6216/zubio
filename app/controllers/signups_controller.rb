class SignupsController < ApplicationController
  skip_before_action :resolve_tenant, only: %i[new create subdomain]
  before_action :redirect_to_platform_host, unless: :platform_root_host?

  # Both limits need an explicit name: Rails keys the counter on
  # controller_path + name, so unnamed limits in one controller share a counter
  # and the subdomain checks would spend the signup quota.
  rate_limit to: 30, within: 1.minute, only: :subdomain, name: "subdomain-check",
    with: -> { head :too_many_requests }

  rate_limit to: 5, within: 1.hour, only: :create, name: "signup",
    with: -> { redirect_to new_signup_path, alert: "Muitas tentativas. Tente novamente mais tarde." }

  def new
    @tenant = Tenant.new
    @user = User.new

    render Views::Signups::New.new(tenant: @tenant, user: @user, branding: Branding.platform_default)
  end

  def subdomain
    candidate = Tenant.clamp_subdomain(params[:candidate])

    render Components::Signup::SubdomainStatus.new(
      status: Tenant.subdomain_status(candidate),
      host: Tenant.host_for(candidate)
    )
  end

  def create
    owner = Tenant.provision_owner!(tenant_attributes: tenant_params, owner_attributes: owner_params)
    OwnerMailer.welcome(owner.tenant_id, owner.id).deliver_later

    redirect_to owner_handoff_url(host: owner.tenant.canonical_host, token: owner.handoff_token), allow_other_host: true
  rescue ActiveRecord::RecordInvalid => invalid
    @tenant = invalid.record.is_a?(Tenant) ? invalid.record : Tenant.new(tenant_params)
    @user = invalid.record.is_a?(User) ? invalid.record : User.new(owner_params)
    render Views::Signups::New.new(tenant: @tenant, user: @user, branding: Branding.platform_default), status: :unprocessable_entity
  end

  private

  def redirect_to_platform_host
    redirect_to new_signup_url(host: Tenant::PLATFORM_HOST), allow_other_host: true
  end

  def tenant_params = params.require(:tenant).permit(:name, :subdomain)
  def owner_params = params.require(:user).permit(:name, :email, :password, :password_confirmation)
end
