class Owner::BaseController < ApplicationController
  class_attribute :panel_section, instance_writer: false

  before_action :require_owner_session!
  before_action :enforce_onboarding_gate

  private

  def require_owner_session!
    redirect_to new_owner_session_path unless current_owner
  end

  def enforce_onboarding_gate
    tenant = ActsAsTenant.current_tenant
    redirect_to onboarding_step_path(tenant.onboarding_step) unless tenant.onboarding_done?
  end

  def onboarding_step_path(step)
    {
      "welcome" => owner_onboarding_welcome_path,
      "colors" => owner_onboarding_colors_path,
      "name" => owner_onboarding_name_path,
      "logo" => owner_onboarding_logo_path,
      "services" => owner_onboarding_services_path,
      "working_hours" => owner_onboarding_working_hours_path
    }.fetch(step)
  end

  def current_owner
    @current_owner ||= session[:user_id] && User.owner.find_by(id: session[:user_id])
  end
end
