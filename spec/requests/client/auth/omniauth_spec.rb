require "rails_helper"

RSpec.describe "Client Google OAuth", type: :request do
  let(:tenant) { create(:tenant, subdomain: "mary") }
  let(:service) { create(:service, tenant: tenant) }

  before do
    host! "zubio.com.br"
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "g-1", info: { email: "ana@gmail.com", name: "Ana Paula Ribeiro" }
    )
  end

  let(:signed_state) do
    Rails.application.message_verifier(:client_oauth_state).generate(
      { "tenant" => tenant.subdomain, "service" => service.id }, expires_in: 10.minutes
    )
  end

  describe "GET /entrar/google" do
    it "renders a self-posting form carrying the signed state to the OAuth request" do
      ActionController::Base.allow_forgery_protection = true
      begin
        get google_entry_path(tenant: "mary", service: service.id)
      ensure
        ActionController::Base.allow_forgery_protection = false
      end

      expect(response.body).to include(%(action="/auth/google_oauth2"), %(data-turbo="false"), %(name="state"), %(name="authenticity_token"))
    end

    it "redirects to the platform host when reached on a tenant subdomain" do
      host! "mary.zubio.com.br"

      get google_entry_path(tenant: "mary", service: service.id)

      expect(response).to redirect_to(root_url(host: Tenant::PLATFORM_HOST))
    end
  end

  describe "GET /auth/google_oauth2/callback" do
    it "hands a linked account to the establishment handoff" do
      linked = ActsAsTenant.with_tenant(tenant) { Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana", phone: "11988771234") }

      get "/auth/google_oauth2/callback", params: { state: signed_state }

      expect(response.location).to start_with(client_handoff_url(host: tenant.canonical_host, token: linked.handoff_token).split("?").first)
      expect(response.location).to include("service=#{service.id}")
    end

    it "sends a brand-new account to the WhatsApp step" do
      get "/auth/google_oauth2/callback", params: { state: signed_state }

      expect(response.location).to start_with(new_client_account_phone_url(host: tenant.canonical_host, token: "x").split("?").first)
    end

    it "refuses a state with a tampered signature" do
      get "/auth/google_oauth2/callback", params: { state: "#{signed_state}x" }

      expect(response).to redirect_to(root_url(host: Tenant::PLATFORM_HOST))
    end

    it "resolves the tenant from the signed state, not from a host or param" do
      other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")

      get "/auth/google_oauth2/callback", params: { state: signed_state, tenant: other_tenant.subdomain }

      expect(response.location).to include(tenant.canonical_host)
      expect(response.location).not_to include(other_tenant.canonical_host)
    end

    it "carries the appointment token into the identity of a brand-new account" do
      state = Rails.application.message_verifier(:client_oauth_state).generate(
        { "tenant" => tenant.subdomain, "service" => service.id, "appointment_token" => "cancel-token-b7f3q9" }, expires_in: 10.minutes
      )

      get "/auth/google_oauth2/callback", params: { state: state }

      identity_token = Rack::Utils.parse_query(URI(response.location).query)["token"]
      identity = Rails.application.message_verifier(:client_google_identity).verify(identity_token)
      expect(identity["appointment_token"]).to eq("cancel-token-b7f3q9")
    end

    it "sends a linked account coming from a receipt to the appointments list handoff" do
      ActsAsTenant.with_tenant(tenant) { Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana", phone: "11988771234") }
      state = Rails.application.message_verifier(:client_oauth_state).generate(
        { "tenant" => tenant.subdomain, "service" => service.id, "appointment_token" => "cancel-token-b7f3q9" }, expires_in: 10.minutes
      )

      get "/auth/google_oauth2/callback", params: { state: state }

      expect(response.location).to include("appointments=1")
      expect(response.location).not_to include("cancel-token-b7f3q9")
    end

    it "sends a linked account without a receipt to the plain handoff" do
      ActsAsTenant.with_tenant(tenant) { Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana", phone: "11988771234") }

      get "/auth/google_oauth2/callback", params: { state: signed_state }

      expect(response.location).not_to include("appointments=")
    end
  end

  describe "logging" do
    it "keeps the identity token of a brand-new account out of the log" do
      log = capture_request_log { get "/auth/google_oauth2/callback", params: { state: signed_state } }

      expect(log).to include("token=[FILTERED]")
      expect(log).not_to match(/token=(?!\[FILTERED\])/)
    end

    it "keeps the handoff token of a linked account out of the log" do
      ActsAsTenant.with_tenant(tenant) { Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana", phone: "11988771234") }

      log = capture_request_log { get "/auth/google_oauth2/callback", params: { state: signed_state } }

      expect(log).to include("token=[FILTERED]")
      expect(log).not_to match(/token=(?!\[FILTERED\])/)
    end
  end

  describe "the real request-to-callback round trip" do
    it "carries the signed state through the OmniAuth redirect instead of relying on a URL param" do
      post "/auth/google_oauth2", params: { state: signed_state }
      follow_redirect!

      expect(response.location).to start_with(new_client_account_phone_url(host: tenant.canonical_host, token: "x").split("?").first)
    end
  end

  describe "failure" do
    it "returns the visitor to a safe page without a 500 when Google denies consent" do
      get "/auth/failure", params: { message: "access_denied" }

      expect(response).to have_http_status(:redirect)
    end
  end
end
