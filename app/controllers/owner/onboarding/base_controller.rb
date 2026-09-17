class Owner::Onboarding::BaseController < Owner::BaseController
  REFUSED = "Não foi possível salvar. Confira os campos destacados.".freeze

  skip_before_action :enforce_onboarding_gate
  before_action :require_current_step

  class_attribute :step, instance_writer: false

  private

  def require_current_step
    tenant = ActsAsTenant.current_tenant
    redirect_to onboarding_step_path(tenant.onboarding_step) unless tenant.onboarding_step == self.class.step
  end

  def advance! = ActsAsTenant.current_tenant.advance_onboarding!
end
