class Client::AppointmentsController < Client::BaseController
  include Client::TokenLookup

  def show
    render Views::Client::Appointments::Show.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      appointment: @appointment,
      service: @appointment.service,
      professional: @appointment.professional
    )
  end
end
