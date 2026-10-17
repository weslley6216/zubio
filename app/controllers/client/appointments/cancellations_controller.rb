class Client::Appointments::CancellationsController < Client::BaseController
  include Client::TokenLookup

  def new
    return redirect_to client_appointment_path(@appointment.cancel_token) unless @appointment.cancellable?

    render Views::Client::Appointments::Cancellations::New.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      appointment: @appointment,
      service: @appointment.service
    )
  end

  def create
    @appointment.cancel!
    redirect_to client_appointment_path(@appointment.cancel_token)
  end
end
