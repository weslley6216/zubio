require "rails_helper"

RSpec.describe "Owner onboarding logo", type: :request do
  def sign_in(tenant)
    owner = create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
    owner
  end

  describe "GET /owner/onboarding/logo" do
    it "shows the logo question with the third-of-five counter" do
      tenant = create(:tenant, :at_logo, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      get owner_onboarding_logo_path

      expect(response.body).to include(Components::Owner::BrandQuestion::Logo::TITLE)
      expect(response.body).to include("3 de 5")
    end
  end

  describe "PATCH /owner/onboarding/logo" do
    it "advances to services without attaching anything when skipped" do
      tenant = create(:tenant, :at_logo, subdomain: "barbearia-do-ze")
      sign_in(tenant)

      patch owner_onboarding_logo_path

      expect(tenant.reload).to be_onboarding_services
      expect(response).to redirect_to(owner_onboarding_services_path)
      ActsAsTenant.with_tenant(tenant) { expect(tenant.branding).to be_nil }
    end

    it "attaches the logo and advances when a valid one is submitted" do
      tenant = create(:tenant, :at_logo, subdomain: "barbearia-do-ze")
      sign_in(tenant)
      logo = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/logo.png"), "image/png")

      patch owner_onboarding_logo_path, params: { branding: { logo: logo } }

      expect(tenant.reload).to be_onboarding_services
      branding = ActsAsTenant.with_tenant(tenant) { tenant.reload.branding }
      expect(branding.logo).to be_attached
    end

    it "rejects an unsupported file type and stays on the logo step" do
      tenant = create(:tenant, :at_logo, subdomain: "barbearia-do-ze")
      sign_in(tenant)
      pdf_file = Tempfile.new([ "logo", ".pdf" ])
      pdf_file.write("%PDF-1.4 fake pdf content")
      pdf_file.rewind

      patch owner_onboarding_logo_path, params: { branding: { logo: Rack::Test::UploadedFile.new(pdf_file.path, "application/pdf") } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(tenant.reload).to be_onboarding_logo
    ensure
      pdf_file.close!
    end

    it "does not affect another tenant's step" do
      tenant = create(:tenant, :at_logo, subdomain: "barbearia-do-ze")
      other_tenant = create(:tenant, :at_logo, subdomain: "other-onboarding")
      sign_in(tenant)

      patch owner_onboarding_logo_path

      expect(other_tenant.reload).to be_onboarding_logo
    end
  end
end
