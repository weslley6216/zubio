class Owner::HandoffsController < ApplicationController
  include Owner::SessionStart
  include NavigationRequest

  REFUSED = "Este link expirou. Entre com seu e-mail e senha.".freeze

  def show
    return redirect_to(new_owner_session_path, alert: REFUSED) unless navigation?

    user = User.find_by_handoff_token(params[:token])

    if user&.owner? && user.tenant_id == ActsAsTenant.current_tenant&.id
      user.consume_handoff_token!
      start_owner_session(user, destination: post_handoff_path)
    else
      redirect_to new_owner_session_path, alert: REFUSED
    end
  end

  private

  def post_handoff_path
    ActsAsTenant.current_tenant&.onboarding_completed? ? owner_onboarding_final_path : owner_appointments_path
  end
end
