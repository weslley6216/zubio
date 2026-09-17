require "rails_helper"

RSpec.describe "Owner onboarding welcome", type: :request do
  def sign_in(tenant)
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
    owner
  end

  describe "GET /owner/onboarding/welcome" do
    it "shows the map of questions and a way to start" do
      tenant = create(:tenant, :onboarding, subdomain: "joes-barbershop")
      sign_in(tenant)

      get owner_onboarding_welcome_path

      expect(response.body).to include("Começar")
    end

    it "redirects an anonymous visitor to login" do
      tenant = create(:tenant, :onboarding, subdomain: "joes-barbershop")
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_onboarding_welcome_path

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "redirects a tenant that has already finished onboarding to the dashboard" do
      tenant = create(:tenant, subdomain: "joes-barbershop")
      sign_in(tenant)

      get owner_onboarding_welcome_path

      expect(response).to redirect_to(owner_dashboard_path)
    end
  end

  describe "PATCH /owner/onboarding/welcome" do
    it "advances to colors and redirects there" do
      tenant = create(:tenant, :onboarding, subdomain: "joes-barbershop")
      sign_in(tenant)

      patch owner_onboarding_welcome_path

      expect(tenant.reload).to be_onboarding_colors
      expect(response).to redirect_to(owner_onboarding_colors_path)
    end

    it "does not move another tenant's step" do
      tenant = create(:tenant, :onboarding, subdomain: "joes-barbershop")
      other_tenant = create(:tenant, :onboarding, subdomain: "other-onboarding")
      sign_in(tenant)

      patch owner_onboarding_welcome_path

      expect(other_tenant.reload).to be_onboarding_welcome
    end
  end
end
