class Client::AppInstallationsController < Client::BaseController
  def create
    return head(:unauthorized) unless current_client

    current_client.record_app_installation!
    head :no_content
  end
end
