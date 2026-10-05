class Owner::ScheduleExceptionsController < Owner::BaseController
  self.panel_section = :settings

  def index
    render screen(exceptions.build(closed: true))
  end

  private

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
