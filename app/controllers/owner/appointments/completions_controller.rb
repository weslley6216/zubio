class Owner::Appointments::CompletionsController < Owner::BaseController
  def create
    appointment = Appointment.find(params[:appointment_id])
    appointment.settle!(:completed)
    redirect_to owner_appointment_path(appointment)
  end
end
