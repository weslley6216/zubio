require "rails_helper"

RSpec.describe "Client session", type: :request do
  let(:tenant) { create(:tenant) }
  let(:service) { create(:service, tenant: tenant) }
  let(:client) { create(:client, tenant: tenant) }

  before { host! "#{tenant.subdomain}.zubio.com.br" }

  describe "GET /session/new (prancheta 17)" do
    it "offers Google and no-account for a tapped service without a session" do
      get new_client_session_path(service_id: service.id)

      expect(response.body).to include("Entre para agendar", "Continuar com o Google", "Continuar sem conta")
      expect(response.body).to include(%(href="#{new_client_service_booking_path(service)}"))
    end
  end

  describe "DELETE /session (logout)" do
    it "clears the client session and returns to the establishment" do
      service
      sign_in_client(client)

      delete client_session_path

      expect(response).to redirect_to(establishment_path)
      follow_redirect!
      expect(response.body).to include(%(href="#{new_client_session_path(service_id: service.id)}"))
    end
  end

  describe "a client session is not an owner session" do
    it "lets an owner session reach the owner dashboard" do
      owner = create(:user, tenant: tenant)
      sign_in_owner(owner)

      get owner_appointments_path

      expect(response).not_to redirect_to(new_owner_session_path)
    end

    it "treats a logged-in client as a visitor on owner routes" do
      sign_in_client(client)

      get owner_appointments_path

      expect(response).to redirect_to(new_owner_session_path)
    end
  end
end
