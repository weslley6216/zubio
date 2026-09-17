class Owner::Onboarding::WorkingHoursController < Owner::Onboarding::BaseController
  self.step = "working_hours"

  def show
    render_hours
  end

  def update
    owner_professional.replace_weekly_hours!(**schedule_params)
    advance!
    OwnerMailer.completed(ActsAsTenant.current_tenant.id, current_owner.id).deliver_later
    redirect_to owner_onboarding_final_path
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = REFUSED
    render_hours(status: :unprocessable_entity)
  end

  private

  def owner_professional = Professional.find_by!(user_id: current_owner.id)

  def schedule_params
    permitted = params.require(:working_hours).permit(:opens_at, :closes_at, :break_starts_at, :break_ends_at, weekdays: [])
    {
      weekdays: Array(permitted[:weekdays]).map(&:to_i),
      opens_at: permitted[:opens_at], closes_at: permitted[:closes_at],
      break_starts_at: permitted[:break_starts_at].presence, break_ends_at: permitted[:break_ends_at].presence
    }
  end

  def render_hours(status: :ok)
    render Views::Owner::Onboarding::Step.new(
      branding: current_branding,
      body: Components::Owner::WorkingHours::Fields.new,
      step: "working_hours", submit_url: owner_onboarding_working_hours_path, submit_label: "Continuar"
    ), status: status
  end
end
