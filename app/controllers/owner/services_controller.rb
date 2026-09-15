class Owner::ServicesController < Owner::BaseController
  REFUSED = "Não foi possível salvar o serviço. Confira os campos destacados.".freeze

  self.panel_section = :services

  def index
    render Views::Owner::Services::Index.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      services: Service.ordered.to_a,
      current_section: panel_section
    )
  end

  def new
    render service_form(Service.new)
  end

  def create
    service = Service.new(service_params)

    if service.save
      redirect_to owner_services_path, notice: "Serviço cadastrado."
    else
      refuse(service)
    end
  end

  private

  def service_params = params.require(:service).permit(:name, :description, :duration_minutes, :price)

  def service_form(service)
    Views::Owner::Services::Form.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      service: service,
      current_section: panel_section
    )
  end

  def refuse(service)
    flash.now[:alert] = REFUSED
    render service_form(service), status: :unprocessable_entity
  end
end
