class Client::EstablishmentsController < Client::BaseController
  def show
    tenant = ActsAsTenant.current_tenant

    render Views::Client::Establishments::Show.new(
      tenant: tenant,
      branding: tenant.branding_or_default,
      services: Service.active.ordered
    )
  end
end
