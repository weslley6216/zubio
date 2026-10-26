class Owner::ClientsController < Owner::BaseController
  self.panel_section = :clients
  self.panel_subtitle = "Clientes"

  def index
    roster = Client::Roster.new(query: params[:q])

    render Views::Owner::Clients::Index.new(
      tenant: ActsAsTenant.current_tenant,
      branding: current_branding,
      entries: roster.entries,
      total: ActsAsTenant.current_tenant.clients.count,
      query: params[:q].to_s,
      current_section: panel_section,
      subtitle: panel_subtitle
    )
  end
end
