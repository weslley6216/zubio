require "rails_helper"

RSpec.describe "Client account phone", type: :request do
  let(:tenant) { create(:tenant) }
  let(:service) { create(:service, tenant: tenant) }

  before { host! "#{tenant.subdomain}.zubio.com.br" }

  def identity_token(uid: "g-1", email: "ana@gmail.com", name: "Ana Paula Ribeiro", service_id: service.id)
    Rails.application.message_verifier(:client_google_identity).generate(
      { "uid" => uid, "email" => email, "name" => name, "service" => service_id }, expires_in: 15.minutes
    )
  end

  it "shows the WhatsApp step with the Google name prefilled" do
    get new_client_account_phone_path(token: identity_token)

    expect(response.body).to include("Qual é o seu WhatsApp?", "Ana Paula Ribeiro")
  end

  it "links the account, starts the session and lands on the service booking" do
    post client_account_phone_path, params: { token: identity_token, phone: "(11) 98877-1234" }

    client = ActsAsTenant.with_tenant(tenant) { Client.find_by(google_uid: "g-1") }
    expect(client.account_linked_at).to be_present
    expect(response).to redirect_to(new_client_service_booking_path(service.id))
  end

  it "reuses a phone-only client without claiming its past appointments" do
    create(:client, tenant: tenant, phone: "11988771234")

    post client_account_phone_path, params: { token: identity_token, phone: "(11) 98877-1234" }

    expect(ActsAsTenant.with_tenant(tenant) { Client.count }).to eq(1)
    linked = ActsAsTenant.with_tenant(tenant) { Client.find_by(phone: "11988771234") }
    expect(linked.account_linked_at).to be_present
  end

  it "refuses a WhatsApp already linked to another Google account" do
    ActsAsTenant.with_tenant(tenant) { Client.link_google!(uid: "g-A", email: "a@gmail.com", name: "A", phone: "11988771234") }

    post client_account_phone_path, params: { token: identity_token(uid: "g-B"), phone: "(11) 98877-1234" }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include(Client::PHONE_TAKEN_MESSAGE)
    linked = ActsAsTenant.with_tenant(tenant) { Client.find_by(phone: "11988771234") }
    expect(linked.google_uid).to eq("g-A")
  end

  it "re-renders the step for a phone too short to be a phone" do
    post client_account_phone_path, params: { token: identity_token, phone: "1198877" }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(ActsAsTenant.with_tenant(tenant) { Client.where(google_uid: "g-1") }).to be_empty
  end

  it "treats a brand-new account as first time in another tenant" do
    aurora = create(:tenant, name: "Estúdio Aurora")
    aurora_client = ActsAsTenant.with_tenant(aurora) { Client.link_google!(uid: "g-1", email: "ana@gmail.com", name: "Ana", phone: "21977665544") }

    post client_account_phone_path, params: { token: identity_token, phone: "(11) 98877-1234" }

    ze_client = ActsAsTenant.with_tenant(tenant) { Client.find_by(google_uid: "g-1") }
    expect(ze_client).to be_present
    expect(ze_client.id).not_to eq(aurora_client.id)
    expect(ze_client.phone).to eq("11988771234")
    expect(aurora_client.reload.phone).to eq("21977665544")
  end

  it "refuses an identity token with a tampered signature" do
    get new_client_account_phone_path(token: "#{identity_token}x")

    expect(response).to redirect_to(establishment_path)
  end
end
