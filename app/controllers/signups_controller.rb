class SignupsController < ApplicationController
  skip_before_action :resolve_tenant, only: %i[new create]

  rate_limit to: 5, within: 1.hour, only: :create,
    with: -> { redirect_to new_signup_path, alert: "Muitas tentativas. Tente novamente mais tarde." }

  def new
    @tenant = Tenant.new
    @user = User.new

    render Views::Signups::New.new(tenant: @tenant, user: @user, branding: Branding.platform_default)
  end

  def create
    @tenant = Tenant.provision!(tenant_attributes: tenant_params, owner_attributes: owner_params)
    redirect_to new_owner_session_url(subdomain: @tenant.subdomain), allow_other_host: true, notice: "Conta criada. Faça login para continuar."
  rescue ActiveRecord::RecordInvalid => invalid
    @tenant = invalid.record.is_a?(Tenant) ? invalid.record : Tenant.new(tenant_params)
    @user = invalid.record.is_a?(User) ? invalid.record : User.new(owner_params)
    render Views::Signups::New.new(tenant: @tenant, user: @user, branding: Branding.platform_default), status: :unprocessable_entity
  end

  private

  def tenant_params = params.require(:tenant).permit(:name, :subdomain)
  def owner_params = params.require(:user).permit(:name, :email, :password, :password_confirmation)
end
