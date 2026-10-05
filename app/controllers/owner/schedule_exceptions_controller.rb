class Owner::ScheduleExceptionsController < Owner::BaseController
  self.panel_section = :settings

  SAVED = "Folga registrada.".freeze
  REFUSED = "Não foi possível registrar. Confira os campos destacados.".freeze
  REMOVED = "Folga removida.".freeze

  def index
    render screen(exceptions.build(closed: true))
  end

  def create
    exception = exceptions.build(exception_attributes)

    if exception.save
      redirect_to owner_schedule_exceptions_path, notice: SAVED
    else
      flash.now[:alert] = REFUSED
      render screen(exception), status: :unprocessable_entity
    end
  end

  def destroy
    exceptions.find(params[:id]).destroy
    redirect_to owner_schedule_exceptions_path, notice: REMOVED
  end

  private

  def exception_attributes
    form = params.require(:schedule_exception)
    attending = form[:attends] == "1"
    attributes = form.permit(:occurs_on, :reason, :opens_at, :closes_at)
    attending ? attributes.merge(closed: false) : attributes.except(:opens_at, :closes_at).merge(closed: true)
  end

  def exceptions = current_owner.professional.schedule_exceptions

  def screen(exception)
    Views::Owner::ScheduleExceptions::Index.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      exceptions: exceptions.upcoming.to_a,
      exception: exception,
      current_section: panel_section
    )
  end
end
