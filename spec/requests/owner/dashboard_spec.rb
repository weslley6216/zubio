require "rails_helper"

RSpec.describe "Owner dashboard", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  def sign_in
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
  end

  describe "GET /owner/dashboard" do
    it "greets the owner by first name and names the establishment" do
      create(:branding, tenant: tenant)
      sign_in

      get owner_dashboard_path

      expect(response.body).to include("Olá, Ana")
      expect(response.body).to include("Estúdio Aurora")
    end

    it "shows the establishment logo when one is attached" do
      create(:branding, :with_logo, tenant: tenant)
      sign_in

      get owner_dashboard_path

      expect(response.body).to include("/rails/active_storage/representations/proxy/")
    end

    it "falls back to the establishment initial when no logo is attached" do
      create(:branding, tenant: tenant)
      sign_in

      get owner_dashboard_path

      expect(response.body).not_to include("/rails/active_storage/representations/proxy/")
      expect(response.body).to include(">E</span>")
    end

    it "applies the tenant's brand through the accent token and its own sheet" do
      branding = create(:branding, tenant: tenant, brand_600: "#2F6FED")
      sign_in

      get owner_dashboard_path

      expect(response.body).to include(%(href="/branding.css?v=#{branding.stylesheet_digest}"))
      expect(response.body).to include("bg-brand-accent")
    end

    it "invites a tenant without a logo to configure its brand" do
      create(:branding, tenant: tenant)
      sign_in

      get owner_dashboard_path

      expect(response.body).to include(Views::Owner::Dashboard::Show::SETUP_BADGE)
      expect(response.body).to include(Views::Owner::Dashboard::Show::SETUP_TITLE)
      expect(response.body).not_to include(Views::Owner::Dashboard::Show::MANAGE_TITLE)
    end

    it "drops the invitation once a logo is attached" do
      create(:branding, :with_logo, tenant: tenant)
      sign_in

      get owner_dashboard_path

      expect(response.body).to include(Views::Owner::Dashboard::Show::MANAGE_TITLE)
      expect(response.body).not_to include(Views::Owner::Dashboard::Show::SETUP_TITLE)
    end

    it "renders the platform default identity for a tenant with no branding at all" do
      sign_in

      get owner_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="/branding.css?v=#{Branding.platform_default.stylesheet_digest}"))
    end

    it "offers a path to the brand screen and a way out of the session" do
      create(:branding, tenant: tenant)
      sign_in

      get owner_dashboard_path

      expect(response.body).to include(%(href="#{edit_owner_branding_path}"))
      expect(response.body).to include(%(action="#{owner_session_path}"))
      expect(response.body).to include(%(value="delete"))
    end

    it "sends an anonymous visitor to the login without naming the establishment" do
      create(:branding, tenant: tenant)
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_dashboard_path

      expect(response).to redirect_to(new_owner_session_path)

      follow_redirect!

      expect(response.body).not_to include("Estúdio Aurora")
    end

    it "shows the identity of the tenant in the host and nothing of another tenant" do
      other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
      other_branding = create(:branding, :with_logo, tenant: other_tenant, brand_600: "#DC2626")
      branding = create(:branding, tenant: tenant, brand_600: "#2F6FED")
      sign_in

      get owner_dashboard_path

      expect(response.body).to include("Estúdio Aurora")
      expect(response.body).not_to include("Barbearia do Zé")
      expect(response.body).to include(branding.stylesheet_digest)
      expect(response.body).not_to include(other_branding.stylesheet_digest)
      expect(response.body).not_to include("/rails/active_storage/representations/proxy/")
    end
  end
end
