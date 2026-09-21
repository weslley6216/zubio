module Owner::SessionStart
  extend ActiveSupport::Concern

  private

  def start_owner_session(user, redirect_to: owner_dashboard_path)
    reset_session
    session[:user_id] = user.id

    redirect_to redirect_to
  end
end
