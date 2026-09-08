class Owner::HandoffsController < ApplicationController
  def show
    user = User.find_by_token_for(:owner_handoff, params[:token])

    if user&.owner?
      reset_session
      session[:user_id] = user.id
      redirect_to owner_dashboard_path
    else
      redirect_to new_owner_session_path, alert: "Este link expirou. Entre com seu e-mail e senha."
    end
  end
end
