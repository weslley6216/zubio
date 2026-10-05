require "rails_helper"

RSpec.describe "Owner dashboard", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  describe "GET /owner/dashboard" do
    it "stacks the panel subtitle under the establishment name in the identity" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_dashboard_path

      subtitle = Nokogiri::HTML5(response.body).at_css("[data-panel-subtitle]")
      expect(subtitle.text).to eq(Components::Owner::Header::PANEL_SUBTITLE)
      expect(subtitle["class"]).to include("text-[11px]", "text-ink-muted")
    end

    it "greets the owner by first name and names the establishment" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response.body).to include("Olá, Ana")
      expect(response.body).to include("Estúdio Aurora")
    end

    it "shows the establishment logo when one is attached" do
      create(:branding, :with_logo, tenant: tenant)
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response.body).to include("/rails/active_storage/representations/proxy/")
    end

    it "falls back to the establishment initial when no logo is attached" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response.body).not_to include("/rails/active_storage/representations/proxy/")
      expect(response.body).to include(">E</span>")
    end

    it "applies the tenant's brand through the accent token and its own sheet" do
      branding = create(:branding, tenant: tenant, brand_600: "#2F6FED")
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response.body).to include(%(href="/branding.css?v=#{branding.stylesheet_digest}"))
      expect(response.body).to include("bg-brand-accent")
    end

    it "shows no brand card for a tenant that has finished onboarding" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response.body).to include("Olá, Ana")
      expect(response.body).not_to include("Configure a marca")
      expect(response.body).not_to include("Marca do estabelecimento")
    end

    it "renders the platform default identity for a tenant with no branding at all" do
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="/branding.css?v=#{Branding.platform_default.stylesheet_digest}"))
    end

    it "offers a path to settings and a way out of the session" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response.body).to include(%(href="#{owner_settings_path}"))
      expect(response.body).to include(%(action="#{owner_session_path}"))
      expect(response.body).to include(%(value="delete"))
    end

    it "sends an anonymous visitor to the login" do
      create(:branding, tenant: tenant)
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_dashboard_path

      expect(response).to redirect_to(new_owner_session_path)
    end

    it "names nothing of the establishment on the login an anonymous visitor lands on" do
      create(:branding, tenant: tenant)
      host! "#{tenant.subdomain}.zubio.com.br"

      get owner_dashboard_path
      follow_redirect!

      expect(response.body).to include(%(action="#{owner_session_path}"))
      expect(response.body).not_to include("Estúdio Aurora")
      expect(response.body).not_to include("wa.me")
    end

    it "shows the establishment public address in full" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response.body).to include("estudio-aurora.zubio.com.br")
    end

    it "writes a WhatsApp message carrying the establishment address" do
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_dashboard_path

      href = Nokogiri::HTML5(response.body).at_css("a[href*='wa.me']")["href"]
      expect(href).to include("estudio-aurora.zubio.com.br")
    end

    it "shows its own host and no other tenant's host" do
      other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
      create(:branding, tenant: tenant)
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response.body).to include("estudio-aurora.zubio.com.br")
      expect(response.body).not_to include("#{other_tenant.subdomain}.zubio.com.br")
    end

    it "shows the identity of the tenant in the host and nothing of another tenant" do
      other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
      other_branding = create(:branding, :with_logo, tenant: other_tenant, brand_600: "#DC2626")
      branding = create(:branding, tenant: tenant, brand_600: "#2F6FED")
      sign_in_owner(owner)

      get owner_dashboard_path

      expect(response.body).to include("Estúdio Aurora")
      expect(response.body).not_to include("Barbearia do Zé")
      expect(response.body).to include(branding.stylesheet_digest)
      expect(response.body).not_to include(other_branding.stylesheet_digest)
      expect(response.body).not_to include("/rails/active_storage/representations/proxy/")
    end
  end
end
