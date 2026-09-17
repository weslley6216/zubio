class Owner::Onboarding::WelcomeController < Owner::Onboarding::BaseController
  self.step = "welcome"

  def show
    render Views::Owner::Onboarding::Welcome.new(tenant: ActsAsTenant.current_tenant, branding: current_branding)
  end

  def update
    advance!
    redirect_to owner_onboarding_colors_path
  end
end
