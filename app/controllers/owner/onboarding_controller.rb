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
  rescue ActiveRecord::RecordInvalid => invalid
    flash.now[:alert] = REFUSED
    render document(invalid: invalid.record), status: :unprocessable_entity
  end

  private

  def document(invalid: nil)
    Views::Owner::Onboarding::Document.new(
      tenant: refill_tenant(invalid),
      branding: refill_branding(invalid),
      services: refill_services(invalid),
      open_section: open_section(invalid),
      page_stylesheet: palette_stylesheet_path(v: Branding::Palette.stylesheet_digest),
      direct_upload_url: rails_direct_uploads_path
    )
  end

  def refill_tenant(invalid)
    return ActsAsTenant.current_tenant if invalid.nil?
    return invalid if invalid.is_a?(Tenant)

    ActsAsTenant.current_tenant.tap { |tenant| tenant.name = name_param }
  end

  def refill_branding(invalid)
    return current_branding if invalid.nil?
    return invalid if invalid.is_a?(Branding)

    (ActsAsTenant.current_tenant.branding || Branding.new).tap { |branding| branding.assign_attributes(color_attrs) }
  end

  def refill_services(invalid)
    return [] if invalid.nil?

    services_attrs.map { |service_attrs| Service.new(service_attrs).tap(&:valid?) }
  end

  def open_section(invalid)
    case invalid
    when Service then "services"
    when WorkingHour then "working_hours"
    when Tenant then "name"
    when Branding then invalid.errors[:logo].present? ? "logo" : "colors"
    else "welcome"
    end
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
      weekdays: Array(permitted[:weekdays]).map(&:to_i),
      opens_at: permitted[:opens_at], closes_at: permitted[:closes_at],
      break_starts_at: permitted[:break_starts_at].presence, break_ends_at: permitted[:break_ends_at].presence
    }
  end

  def owner_professional = Professional.find_by!(user_id: current_owner.id)
end
