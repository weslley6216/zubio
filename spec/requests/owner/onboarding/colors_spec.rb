require "rails_helper"

RSpec.describe "Owner onboarding colors", type: :request do
  def sign_in(tenant)
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
    owner
  end

  describe "GET /owner/onboarding/colors" do
    it "shows the colors question with the first-of-five counter" do
      tenant = create(:tenant, :at_colors, subdomain: "joes-barbershop")
      sign_in(tenant)

      get owner_onboarding_colors_path

      expect(response.body).to include(Components::Owner::BrandQuestion::Colors::TITLE)
      expect(response.body).to include("1 de 5")
    end

    it "redirects a tenant that has already finished onboarding to the dashboard" do
      tenant = create(:tenant, subdomain: "joes-barbershop")
      sign_in(tenant)

      get owner_onboarding_colors_path

      expect(response).to redirect_to(owner_dashboard_path)
    end
  end

  describe "PATCH /owner/onboarding/colors" do
    it "saves the color, advances to name, and paints the next step already" do
      tenant = create(:tenant, :at_colors, subdomain: "joes-barbershop")
      sign_in(tenant)

      patch owner_onboarding_colors_path, params: { branding: { brand_600: "#2F6FED" } }

      expect(tenant.reload).to be_onboarding_name
      branding = ActsAsTenant.with_tenant(tenant) { tenant.reload.branding }
      expect(branding.brand_600).to eq("#2F6FED")
      expect(response).to redirect_to(owner_onboarding_name_path)

      follow_redirect!

      expect(response.body).to include("2 de 5")
      expect(response.body).to include(%(href="/branding.css?v=#{branding.stylesheet_digest}"))
    end

    it "rejects an invalid color and stays on the colors step" do
      tenant = create(:tenant, :at_colors, subdomain: "joes-barbershop")
      sign_in(tenant)

      patch owner_onboarding_colors_path, params: { branding: { brand_600: "not-a-hex" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tenant.reload).to be_onboarding_colors
    end

    it "does not affect another tenant's branding or step" do
      tenant = create(:tenant, :at_colors, subdomain: "joes-barbershop")
      other_tenant = create(:tenant, :at_colors, subdomain: "other-onboarding")
      sign_in(tenant)

      patch owner_onboarding_colors_path, params: { branding: { brand_600: "#2F6FED" } }

      expect(other_tenant.reload).to be_onboarding_colors
      ActsAsTenant.with_tenant(other_tenant) { expect(other_tenant.branding).to be_nil }
    end
  end
end
