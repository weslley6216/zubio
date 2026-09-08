class Owner::SessionsController < ApplicationController
  include Owner::SessionStart

  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_owner_session_path, alert: "Muitas tentativas. Tente de novo em alguns minutos." }

  def new
    render Views::Owner::Sessions::New.new(branding: current_branding)
  end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])

    if user&.owner?
      start_owner_session(user)
    else
      redirect_to new_owner_session_path, alert: "E-mail ou senha inválidos."
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to new_owner_session_path
  end
end
