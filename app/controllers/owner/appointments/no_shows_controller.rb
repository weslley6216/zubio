class Owner::Appointments::NoShowsController < Owner::BaseController
  def create
    appointment = Appointment.find(params[:appointment_id])
    appointment.settle!(:no_show)
    redirect_to owner_appointment_path(appointment)
  end
end
