class Client::SessionsController < Client::BaseController
  def new
    service = Service.active.find(params[:service_id])
    render Views::Client::Sessions::New.new(tenant: ActsAsTenant.current_tenant, branding: current_branding, service: service)
  end

  def destroy
    reset_client_session
    redirect_to establishment_path
  end
end
