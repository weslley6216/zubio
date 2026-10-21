class Client::MyAppointmentsController < Client::BaseController
  def index
    return redirect_to(establishment_path) unless current_client

    render Views::Client::MyAppointments::Index.new(
      tenant: ActsAsTenant.current_tenant, branding: current_branding,
      appointments: Appointment.visible_to_account(current_client).includes(:service)
    )
  end
end
