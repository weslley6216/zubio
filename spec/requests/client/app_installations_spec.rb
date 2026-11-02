require "rails_helper"

RSpec.describe "Client app installations", type: :request do
  it "records the installation for the signed-in client" do
    client = create(:client)
    sign_in_client(client)

    post client_app_installation_path

    expect(client.reload.app_installed_at).to be_present
  end

  it "without a session, refuses and records nothing" do
    client = create(:client)
    host! "#{client.tenant.subdomain}.zubio.com.br"

    post client_app_installation_path

    expect(response).to have_http_status(:unauthorized)
    expect(client.reload.app_installed_at).to be_nil
  end

  it "posting on tenant A's session does not stamp tenant B's client" do
    ze = create(:tenant, name: "Barbearia do Zé")
    aurora = create(:tenant, name: "Estúdio Aurora")
    client_ze = create(:client, tenant: ze)
    client_aurora = create(:client, tenant: aurora)
    sign_in_client(client_ze)

    post client_app_installation_path

    expect(client_aurora.reload.app_installed_at).to be_nil
  end
end
