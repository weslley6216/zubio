module Client::TokenLookup
  extend ActiveSupport::Concern

  included do
    before_action :set_appointment
  end

  private

  def set_appointment
    @appointment = Appointment.find_by(cancel_token: params[:token])
    head :not_found if @appointment.nil?
  end
end
