class Owner::HandoffsController < ApplicationController
  include Owner::SessionStart

  EXPIRED = "Este link expirou. Entre com seu e-mail e senha.".freeze

  def show
    user = User.find_by_handoff_token(params[:token])

    if user&.owner? && user.tenant_id == ActsAsTenant.current_tenant&.id
      user.consume_handoff_token!
      start_owner_session(user)
    else
      redirect_to new_owner_session_path, alert: EXPIRED
    end
  end
end
