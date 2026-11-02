module Owner::CurrentOwner
  extend ActiveSupport::Concern

  private

  def current_owner
    @current_owner ||= begin
      session_record = cookies.signed[:session_id] && Session.find_by(id: cookies.signed[:session_id])
      session_record&.user if session_record&.user&.owner?
    end
  end
end
