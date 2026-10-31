class Client::Appointments::ReceiptsController < Client::BaseController
  include Client::TokenLookup

  def show
    return redirect_to client_appointment_path(@appointment.cancel_token) unless @appointment.confirmed?

    render Views::Client::Bookings::Receipt.new(
      tenant: ActsAsTenant.current_tenant, branding: current_branding, service: @appointment.service,
      professional: @appointment.professional, appointment: @appointment, signed_in: current_client.present?
    )
  end
end
