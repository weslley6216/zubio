class Owner::Appointments::CancellationsController < Owner::BaseController
  def create
    appointment = Appointment.find(params[:appointment_id])
    appointment.cancel!
    redirect_to owner_appointment_path(appointment)
  end
end
