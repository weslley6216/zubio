require "rails_helper"

RSpec.describe "Owner onboarding name", type: :request do
  def sign_in(tenant)
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
    owner
  end

  describe "GET /owner/onboarding/name" do
    it "shows an empty name field, a provisional address that does not leak the owner's name, and the second-of-five counter" do
      tenant = create(:tenant, :at_name, subdomain: "abc123def456")
      sign_in(tenant)

      get owner_onboarding_name_path

      expect(response.body).to include(%(id="tenant_name" name="tenant[name]"))
      expect(response.body).not_to include(%(id="tenant_name" name="tenant[name]" value="Ana"))
      expect(response.body).not_to include("Ana Lima")
      expect(response.body).to include("2 de 5")
    end

    it "redirects a tenant that has already finished onboarding to the dashboard" do
      tenant = create(:tenant, subdomain: "joes-barbershop")
      sign_in(tenant)

      get owner_onboarding_name_path

      expect(response).to redirect_to(owner_dashboard_path)
    end
  end

  describe "PATCH /owner/onboarding/name" do
    it "derives the subdomain from the brand name and hands the session over to the new host" do
      tenant = create(:tenant, :at_name, subdomain: "abc123def456")
      owner = sign_in(tenant)

      patch owner_onboarding_name_path, params: { tenant: { name: "Barbearia do Zé" } }

      expect(tenant.reload).to have_attributes(name: "Barbearia do Zé", subdomain: "barbearia-do-ze")
      expect(response.location).to start_with(owner_handoff_url(subdomain: "barbearia-do-ze"))
      expect(response.location).to include("token=")
    end

    it "hands out the already-reserved subdomain when the derived one collides" do
      create(:tenant, subdomain: "barbearia-do-ze")
      tenant = create(:tenant, :at_name, subdomain: "abc123def456")
      sign_in(tenant)

      patch owner_onboarding_name_path, params: { tenant: { name: "Barbearia do Zé" } }

      expect(tenant.reload.subdomain).to eq("barbearia-do-ze-2")
      expect(response.location).to start_with(owner_handoff_url(subdomain: "barbearia-do-ze-2"))
    end

    it "does not hand out a reserved subdomain" do
      tenant = create(:tenant, :at_name, subdomain: "abc123def456")
      sign_in(tenant)

      patch owner_onboarding_name_path, params: { tenant: { name: "Admin" } }

      expect(tenant.reload.subdomain).to eq("admin-2")
    end

    it "rejects a blank name and stays on the name step" do
      tenant = create(:tenant, :at_name, subdomain: "abc123def456")
      original_subdomain = tenant.subdomain
      sign_in(tenant)

      patch owner_onboarding_name_path, params: { tenant: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tenant.reload.subdomain).to eq(original_subdomain)
    end

    it "does not affect another tenant's address or step" do
      tenant = create(:tenant, :at_name, subdomain: "abc123def456")
      other_tenant = create(:tenant, :at_name, subdomain: "other123abc456")
      sign_in(tenant)

      patch owner_onboarding_name_path, params: { tenant: { name: "Barbearia do Zé" } }

      expect(other_tenant.reload).to have_attributes(name: nil, subdomain: "other123abc456")
      expect(other_tenant).to be_onboarding_name
    end
  end
end
