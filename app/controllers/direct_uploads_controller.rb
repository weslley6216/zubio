class DirectUploadsController < ActiveStorage::DirectUploadsController
  include TenantResolution
  include Owner::CurrentOwner

  before_action :require_owner!

  private

  def require_owner!
    head :unauthorized unless current_owner
  end
end
