class Owner::Onboarding::ColorsController < Owner::Onboarding::BaseController
  include Owner::ColorSubmission

  self.step = "colors"

  def show
    render_colors
  end

  def update
    ActsAsTenant.current_tenant.update_branding!(tenant_attrs: {}, branding_attrs: color_attrs, remove_logo: false)
    advance!
    redirect_to owner_onboarding_name_path
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = REFUSED
    render_colors(status: :unprocessable_entity)
  end

  private

  def render_colors(status: :ok)
    render Views::Owner::Onboarding::Step.new(
      tenant: ActsAsTenant.current_tenant, branding: current_branding,
      body: Components::Owner::BrandQuestion::Colors.new(tenant: ActsAsTenant.current_tenant, branding: current_branding),
      step: "colors", submit_url: owner_onboarding_colors_path, submit_label: "Continuar",
      page_stylesheet: palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)
    ), status: status
  end
end
