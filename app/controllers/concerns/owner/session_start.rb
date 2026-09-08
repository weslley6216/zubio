# Every path that signs an owner in goes through here: reset_session before
# writing user_id is the session-fixation guard, and having one entry point is
# what keeps a future login path from silently omitting it.
module Owner::SessionStart
  extend ActiveSupport::Concern

  private

  def start_owner_session(user)
    reset_session
    session[:user_id] = user.id

    redirect_to owner_dashboard_path
  end
end
