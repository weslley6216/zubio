require "rails_helper"

RSpec.describe "Client Google sign-in start", type: :request do
  let(:tenant) { create(:tenant, subdomain: "mary", name: "Mary Sombracelhas") }
  let(:service) { create(:service, tenant: tenant) }

  before { host! "#{tenant.subdomain}.zubio.com.br" }

  it "sends the visitor to the platform Google entry for the host's establishment and the tapped service" do
    get client_google_sign_in_path(service: service.id)

    query = Rack::Utils.parse_query(URI(response.location).query)
    expect(response.location).to start_with(google_entry_url(host: Tenant::PLATFORM_HOST))
    expect(query).to include("tenant" => "mary", "service" => service.id.to_s)
  end

  it "carries the appointments destination and the receipt token" do
    get client_google_sign_in_path(appointments: "1", appointment_token: "cancel-token-b7f3q9")

    query = Rack::Utils.parse_query(URI(response.location).query)
    expect(query).to include("appointments" => "1", "appointment_token" => "cancel-token-b7f3q9")
  end

  it "hands the platform a fresh nonce for each start" do
    get client_google_sign_in_path(service: service.id)
    first_nonce = Rack::Utils.parse_query(URI(response.location).query)["nonce"]

    get client_google_sign_in_path(service: service.id)

    expect(first_nonce).to be_present
    expect(Rack::Utils.parse_query(URI(response.location).query)["nonce"]).not_to eq(first_nonce)
  end

  it "resolves the establishment from the host, never from a param" do
    other_tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")

    get client_google_sign_in_path(tenant: other_tenant.subdomain)

    query = Rack::Utils.parse_query(URI(response.location).query)
    expect(query["tenant"]).to eq("mary")
    expect(query["tenant"]).not_to eq("barbearia-do-ze")
  end
end
