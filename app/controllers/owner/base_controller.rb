class Owner::BaseController < ApplicationController
  before_action :require_owner_session!

  private

  def require_owner_session!
    redirect_to new_owner_session_path unless current_owner
  end

  def current_owner
    @current_owner ||= session[:user_id] && User.owner.find_by(id: session[:user_id])
  end
end
