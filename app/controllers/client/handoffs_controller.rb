class Client::HandoffsController < Client::BaseController
  include NavigationRequest

  def show
    return redirect_to(establishment_path) unless navigation?

    client = Client.find_by_handoff_token(params[:token])

    if client && client.tenant_id == ActsAsTenant.current_tenant&.id
      client.consume_handoff_token!
      start_client_session(client, destination: destination)
    else
      redirect_to establishment_path
    end
  end

  private

  def destination
    params[:service].present? ? new_client_service_booking_path(params[:service]) : establishment_path
  end
end
