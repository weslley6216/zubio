class Owner::OnboardingController < Owner::BaseController
  include Owner::ColorSubmission

  REFUSED = "Não foi possível salvar. Confira os campos destacados.".freeze

  skip_before_action :enforce_onboarding_gate

  def show
    return redirect_to owner_dashboard_path if ActsAsTenant.current_tenant.onboarding_completed?

    render document
  end

  def create
    tenant = ActsAsTenant.current_tenant
    tenant.complete_onboarding!(
      name: name_param,
      branding_attrs: branding_attrs,
      services_attrs: services_attrs,
      schedule: schedule_params,
      professional: owner_professional
    )
    OwnerMailer.completed(tenant.id, current_owner.id).deliver_later
    redirect_to owner_handoff_url(host: tenant.canonical_host, token: current_owner.handoff_token), allow_other_host: true
  rescue Tenant::OnboardingRejected => rejection
    flash.now[:alert] = REFUSED
    render document(rejection: rejection), status: :unprocessable_entity
  end

  private

  def document(rejection: nil)
    Views::Owner::Onboarding::Document.new(
      tenant: rejection&.tenant || ActsAsTenant.current_tenant,
      branding: rejection&.branding || current_branding,
      services: rejection&.services || [],
      schedule: rejection&.schedule,
      open_section: open_section(rejection),
      page_stylesheet: palette_stylesheet_path(v: Branding::Palette.stylesheet_digest),
      direct_upload_url: rails_direct_uploads_path
    )
  end

  def open_section(rejection)
    return "welcome" if rejection.nil?

    branding_errors = rejection.branding.errors
    return "colors" if branding_errors[:brand_600].present? || branding_errors[:brand_secondary_600].present?
    return "name" if rejection.tenant.errors[:name].present?
    return "logo" if branding_errors[:logo].present?
    return "services" if rejection.services.any? { |service| service.errors.present? }
    return "working_hours" if rejection.schedule.errors.present?

    "welcome"
  end

  def name_param = params.dig(:tenant, :name).to_s

  def branding_attrs = color_attrs.merge(logo_attrs)

  def logo_attrs = params.dig(:branding, :logo).present? ? { logo: params[:branding][:logo] } : {}

  def services_attrs
    Array(params[:services])
      .map { |service| service.permit(:name, :description, :duration_minutes, :price) }
      .reject { |service| service.values_at(:name, :duration_minutes, :price).all?(&:blank?) }
  end

  def schedule_params
    permitted = params.fetch(:working_hours, {}).permit(:opens_at, :closes_at, :break_starts_at, :break_ends_at, weekdays: [])
    {
      weekdays: Array(permitted[:weekdays]).compact_blank.map(&:to_i),
      opens_at: permitted[:opens_at], closes_at: permitted[:closes_at],
      break_starts_at: permitted[:break_starts_at].presence, break_ends_at: permitted[:break_ends_at].presence
    }
  end

  def owner_professional = Professional.find_by!(user_id: current_owner.id)
end
