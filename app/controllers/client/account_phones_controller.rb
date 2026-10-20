class Client::AccountPhonesController < Client::BaseController
  before_action :decode_identity

  def new
    render Views::Client::AccountPhones::New.new(
      tenant: ActsAsTenant.current_tenant, branding: current_branding, name: @identity["name"], token: params[:token]
    )
  end

  def create
    client = Client.link_google!(uid: @identity["uid"], email: @identity["email"], name: @identity["name"], phone: params[:phone])

    if client.errors.empty?
      start_client_session(client, destination: destination)
    else
      render Views::Client::AccountPhones::New.new(
        tenant: ActsAsTenant.current_tenant, branding: current_branding, name: @identity["name"], token: params[:token], client: client
      ), status: :unprocessable_entity
    end
  end

  private

  def destination
    @identity["service"].present? ? new_client_service_booking_path(@identity["service"]) : establishment_path
  end

  def decode_identity
    @identity = Rails.application.message_verifier(:client_google_identity).verify(params[:token])
    redirect_to establishment_path unless @identity["tenant"] == ActsAsTenant.current_tenant.subdomain
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to establishment_path
  end
end
