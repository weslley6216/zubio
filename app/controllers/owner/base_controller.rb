class Owner::BaseController < ApplicationController
  class_attribute :panel_section, instance_writer: false

  before_action :require_owner_session!
  before_action :enforce_onboarding_gate

  private

  def require_owner_session!
    redirect_to new_owner_session_path unless current_owner
  end

  def enforce_onboarding_gate
    redirect_to owner_onboarding_path unless ActsAsTenant.current_tenant.onboarding_completed?
  end

  def current_owner
    @current_owner ||= session[:user_id] && User.owner.find_by(id: session[:user_id])
  end
end
