class Client::Auth::OmniauthController < ApplicationController
  skip_before_action :resolve_tenant
  before_action :redirect_to_platform_root, unless: :platform_root_host?

  def new
    state = Rails.application.message_verifier(:client_oauth_state).generate(
      { "tenant" => params[:tenant], "service" => params[:service] }, expires_in: 10.minutes
    )
    render Views::Client::Auth::Redirect.new(state: state)
  end

  def callback
    auth = request.env["omniauth.auth"]
    data = Rails.application.message_verifier(:client_oauth_state).verify(signed_state)
    tenant = Tenant.active.find_by(subdomain: data["tenant"])

    return redirect_to_platform_root if tenant.nil?

    client = ActsAsTenant.with_tenant(tenant) { Client.find_by(google_uid: auth.uid) }

    if client
      redirect_to client_handoff_url(host: tenant.canonical_host, token: client.handoff_token, service: data["service"]), allow_other_host: true
    else
      identity = Rails.application.message_verifier(:client_google_identity).generate(
        { "tenant" => tenant.subdomain, "uid" => auth.uid, "email" => auth.info.email, "name" => auth.info.name, "service" => data["service"] }, expires_in: 15.minutes
      )
      redirect_to new_client_account_phone_url(host: tenant.canonical_host, token: identity), allow_other_host: true
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to_platform_root
  end

  def failure
    redirect_to_platform_root(alert: "Não foi possível entrar com o Google. Tente de novo.")
  end

  private

  def signed_state
    request.env["omniauth.origin"].presence || params[:state]
  end

  def redirect_to_platform_root(alert: nil)
    redirect_to root_url(host: Tenant::PLATFORM_HOST), allow_other_host: true, alert: alert
  end
end
