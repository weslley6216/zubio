class SignupsController < ApplicationController
  skip_before_action :resolve_tenant, only: %i[new create]
  before_action :redirect_to_platform_host, unless: :platform_root_host?

  rate_limit to: 5, within: 1.hour, only: :create, name: "signup",
    with: -> { redirect_to new_signup_path, alert: "Muitas tentativas. Tente novamente mais tarde." }

  def new
    render Views::Signups::New.new(user: new_user, branding: Branding.platform_default)
  end

  def create
    owner = Tenant.provision_owner!(owner_attributes: owner_params)
    OwnerMailer.welcome(owner.tenant_id, owner.id).deliver_later

    redirect_to owner_handoff_url(host: owner.tenant.canonical_host, token: owner.handoff_token), allow_other_host: true
  rescue ActiveRecord::RecordInvalid => invalid
    user = invalid.record.is_a?(User) ? invalid.record : new_user(owner_params)

    render Views::Signups::New.new(user: user, branding: Branding.platform_default), status: :unprocessable_entity
  end

  private

  def new_user(attributes = {})
    ActsAsTenant.without_tenant { User.new(attributes) }
  end

  def redirect_to_platform_host
    redirect_to new_signup_url(host: Tenant::PLATFORM_HOST), allow_other_host: true
  end

  def owner_params = params.require(:user).permit(:name, :email, :password)
end
