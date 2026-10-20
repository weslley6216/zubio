class Client::EstablishmentsController < Client::BaseController
  def show
    tenant = ActsAsTenant.current_tenant
    professional = tenant.professionals.active.first

    render Views::Client::Establishments::Show.new(
      tenant: tenant,
      branding: tenant.branding_or_default,
      services: Service.active.ordered.to_a,
      open_until: professional && Professional::Availability.new(professional: professional).open_until(Time.current),
      authenticated: current_client.present?
    )
  end
end
