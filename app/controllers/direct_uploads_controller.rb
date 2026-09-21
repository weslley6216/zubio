class DirectUploadsController < ActiveStorage::DirectUploadsController
  before_action :require_session!

  private

  def require_session!
    head :unauthorized if session[:user_id].blank?
  end
end
