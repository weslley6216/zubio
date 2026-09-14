class Owner::ServicesController < Owner::BaseController
  self.panel_section = :services

  def index
    render Views::Owner::Services::Index.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      services: Service.ordered.to_a,
      current_section: panel_section
    )
  end
end
