class Client::GoogleSignInsController < Client::BaseController
  include Client::GoogleNonce

  def show
    redirect_to google_entry_url(
      host: Tenant::PLATFORM_HOST, tenant: ActsAsTenant.current_tenant.subdomain, nonce: issue_google_nonce,
      **params.permit(:service, :appointments, :appointment_token).to_h.symbolize_keys
    ), allow_other_host: true
  end
end
