module Owner::SessionStart
  extend ActiveSupport::Concern

  private

  def start_owner_session(user, destination: owner_appointments_path)
    reset_session
    new_session = user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
    cookies.signed.permanent[:session_id] = {
      value: new_session.id, httponly: true, same_site: :lax, secure: Rails.env.production?
    }

    redirect_to destination
  end

  def terminate_owner_session
    Session.find_by(id: cookies.signed[:session_id])&.destroy
    cookies.delete(:session_id)
  end
end
