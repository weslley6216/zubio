require "rails_helper"

RSpec.describe "Client handoff", type: :request do
  let(:tenant) { create(:tenant) }
  let(:client) { create(:client, tenant: tenant) }
  let(:service) { create(:service, tenant: tenant) }

  before { host! "#{tenant.subdomain}.zubio.com.br" }

  it "opens the client session and lands on the tapped service booking" do
    get client_handoff_path(token: client.handoff_token, service: service.id)

    expect(response).to redirect_to(new_client_service_booking_path(service.id))
  end

  it "refuses the same handoff token a second time" do
    token = client.handoff_token
    get client_handoff_path(token: token)

    get client_handoff_path(token: token)

    expect(response).to redirect_to(establishment_path)
  end

  it "refuses a handoff token minted for another tenant" do
    other_tenant = create(:tenant, name: "Estúdio Aurora")
    other_client = create(:client, tenant: other_tenant)

    get client_handoff_path(token: other_client.handoff_token)

    expect(response).to redirect_to(establishment_path)
  end

  it "opens the session for a handoff token minted in the same tenant" do
    service

    get client_handoff_path(token: client.handoff_token)

    expect(response).to redirect_to(establishment_path)
    follow_redirect!
    expect(response.body).to include(%(href="#{new_client_service_booking_path(service)}"))
  end

  it "refuses a token that arrives as a subresource instead of a navigation" do
    get client_handoff_path(token: client.handoff_token), headers: { "Sec-Fetch-Dest" => "image" }

    expect(response).to redirect_to(establishment_path)
  end
end
