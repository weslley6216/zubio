module Client::CurrentClient
  extend ActiveSupport::Concern

  private

  def current_client
    @current_client ||= cookies.encrypted[:client_id] && ActsAsTenant.current_tenant.clients.find_by(id: cookies.encrypted[:client_id])
  end

  def start_client_session(client, destination:)
    cookies.encrypted[:client_id] = { value: client.id, httponly: true }
    redirect_to destination
  end

  def reset_client_session
    cookies.delete(:client_id)
  end
end
