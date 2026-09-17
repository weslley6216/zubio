class Owner::Onboarding::ServicesController < Owner::Onboarding::BaseController
  self.step = "services"

  def show
    render_services(Service.new)
  end

  def create
    service = Service.new(service_params)

    if service.save
      redirect_to owner_onboarding_services_path, notice: "Serviço cadastrado."
    else
      flash.now[:alert] = "Não foi possível salvar o serviço. Confira os campos destacados."
      render_services(service, status: :unprocessable_entity)
    end
  end

  def update
    advance!
    redirect_to owner_onboarding_working_hours_path
  end

  private

  def service_params = params.require(:service).permit(:name, :description, :duration_minutes, :price)

  def render_services(service, status: :ok)
    render Views::Owner::Onboarding::Services.new(
      tenant: ActsAsTenant.current_tenant, branding: current_branding,
      service: service, services: Service.ordered.to_a
    ), status: status
  end
end
