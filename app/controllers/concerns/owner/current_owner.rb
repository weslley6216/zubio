module Owner::CurrentOwner
  extend ActiveSupport::Concern

  private

  def current_owner
    @current_owner ||= session[:user_id] && User.owner.find_by(id: session[:user_id])
  end
end
