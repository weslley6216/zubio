class Owner::WorkingHoursController < Owner::BaseController
  REFUSED = "Não foi possível salvar os horários. Confira os dias destacados.".freeze
  SAVED = "Horários atualizados.".freeze

  self.panel_section = :settings

  def edit
    render screen(WeeklySchedule.from_professional(current_owner.professional))
  end

  def update
    schedule = WeeklySchedule.new(professional: current_owner.professional, days: schedule_params)

    if schedule.save
      redirect_to edit_owner_working_hours_path, notice: SAVED
    else
      flash.now[:alert] = REFUSED
      render screen(schedule), status: :unprocessable_entity
    end
  end

  private

  def screen(schedule)
    Views::Owner::WorkingHours::Edit.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      schedule: schedule,
      current_section: panel_section
    )
  end

  def schedule_params
    permitted = WorkingHour::WEEKDAYS.index_with { WeeklySchedule::DAY_PARAM_KEYS }.transform_keys(&:to_s)
    params.fetch(:working_hours, {}).permit(permitted).to_h
  end
end
