require "rails_helper"

RSpec.describe "Owner onboarding final", type: :request do
  def sign_in(tenant)
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
    owner
  end

  describe "GET /owner/onboarding/final" do
    it "shows the full address, the copy and WhatsApp actions, and the summary" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      owner = sign_in(tenant)
      professional = ActsAsTenant.with_tenant(tenant) { create(:professional, tenant: tenant, user: owner) }
      ActsAsTenant.with_tenant(tenant) { create(:service, tenant: tenant, name: "Corte") }
      ActsAsTenant.with_tenant(tenant) { professional.replace_weekly_hours!(weekdays: [ 2, 3 ], opens_at: "09:00", closes_at: "18:00") }

      get owner_onboarding_final_path

      expect(response.body).to include("barbearia-do-ze.zubio.com.br")
      expect(response.body).to include("Barbearia do Zé")
      expect(response.body).to include("1 serviço")
      expect(response.body).to include("wa.me")
    end

    it "names the missing service and leads back to registering one" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      owner = sign_in(tenant)
      ActsAsTenant.with_tenant(tenant) { create(:professional, tenant: tenant, user: owner) }

      get owner_onboarding_final_path

      expect(response.body).to include("Nenhum serviço cadastrado")
      expect(response.body).to include(%(href="#{new_owner_service_path}"))
    end

    it "sends a tenant still mid-onboarding to the onboarding document instead" do
      tenant = create(:tenant, :onboarding, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      get owner_onboarding_final_path

      expect(response).to redirect_to(owner_onboarding_path)
    end

    it "lets a tenant who has finished onboarding reach the panel, with no way back into setup" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      sign_in(tenant)

      get owner_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(owner_onboarding_path)
    end

    it "does not leak another tenant's summary" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      sign_in(tenant)

      get owner_onboarding_final_path

      expect(response.body).not_to include("Estúdio Aurora")
      expect(response.body).not_to include(other_tenant.canonical_host)
    end
  end
end
