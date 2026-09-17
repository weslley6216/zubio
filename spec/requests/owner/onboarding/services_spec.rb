require "rails_helper"

RSpec.describe "Owner onboarding services", type: :request do
  def sign_in(tenant)
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
    owner
  end

  describe "GET /owner/onboarding/services" do
    it "shows the services question with the fourth-of-five counter and an empty list" do
      tenant = create(:tenant, :at_services, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      get owner_onboarding_services_path

      expect(response.body).to include("4 de 5")
      expect(response.body).to include("Nenhum serviço cadastrado")
    end

    it "redirects a tenant that has already finished onboarding to the dashboard" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      get owner_onboarding_services_path

      expect(response).to redirect_to(owner_dashboard_path)
    end
  end

  describe "POST /owner/onboarding/services" do
    it "adds the service, stays on the step, and lists it with the updated count" do
      tenant = create(:tenant, :at_services, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      post owner_onboarding_services_path, params: { service: { name: "Corte", duration_minutes: 45, price: "90,00" } }
      follow_redirect!

      expect(tenant.reload).to be_onboarding_services
      expect(response.body).to include("Corte")
      expect(response.body).to include("1 serviço")
    end

    it "rejects an invalid service and stays on the step" do
      tenant = create(:tenant, :at_services, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      post owner_onboarding_services_path, params: { service: { name: "", duration_minutes: 45, price: "90,00" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a service for another tenant" do
      tenant = create(:tenant, :at_services, subdomain: "barbearia-do-ze")
      other_tenant = create(:tenant, :at_services, subdomain: "other-onboarding")
      sign_in(tenant)

      post owner_onboarding_services_path, params: { service: { name: "Corte", duration_minutes: 45, price: "90,00" } }

      ActsAsTenant.with_tenant(other_tenant) { expect(Service.count).to eq(0) }
    end
  end

  describe "PATCH /owner/onboarding/services" do
    it "advances to working hours even with zero services" do
      tenant = create(:tenant, :at_services, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      patch owner_onboarding_services_path

      expect(tenant.reload).to be_onboarding_working_hours
      expect(response).to redirect_to(owner_onboarding_working_hours_path)
    end

    it "does not move another tenant's step" do
      tenant = create(:tenant, :at_services, subdomain: "barbearia-do-ze")
      other_tenant = create(:tenant, :at_services, subdomain: "other-onboarding")
      sign_in(tenant)

      patch owner_onboarding_services_path

      expect(other_tenant.reload).to be_onboarding_services
    end
  end
end
