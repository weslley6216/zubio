require "rails_helper"

RSpec.describe "Owner session", type: :request do
  let(:tenant) { create(:tenant, subdomain: "joes-barbershop") }

  before { host! "#{tenant.subdomain}.zubio.com.br" }

  describe "GET /owner/session/new" do
    it "renders the login form" do
      get new_owner_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Entrar")
    end

    it "prefills the email that arrived from the login link" do
      get new_owner_session_path(email: "ze@example.com")

      expect(response.body).to include(%(value="ze@example.com"))
    end

    it "links to the password reset form" do
      get new_owner_session_path

      expect(response.body).to include(%(href="#{new_owner_password_reset_path}"))
      expect(response.body).to include("Esqueci minha senha")
    end

    it "renders the alert message outlined in the danger color after an invalid login attempt" do
      create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")

      post owner_session_path, params: { email: "owner@example.com", password: "wrong" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("E-mail ou senha inválidos.")
      expect(response.body).to include(%(class="#{Components::Alert::FRAME_CLASS} border-danger"))
      expect(response.body).to include("text-danger")
    end

    it "renders no platform chrome on the tenant's own host" do
      branding = create(:branding, tenant: tenant, brand_600: "#4F46E5")

      get new_owner_session_path

      expect(response.body).to include(%(href="/branding.css?v=#{branding.stylesheet_digest}"))
      expect(response.body).not_to include(%(aria-label="Trocar o tema"))
    end

    it "renders the brand of the tenant in the host and nothing of another tenant" do
      other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
      branding = create(:branding, tenant: tenant, brand_600: "#4F46E5")
      other_branding = create(:branding, tenant: other_tenant, brand_600: "#DC2626")

      get new_owner_session_path

      expect(response.body).to include(branding.stylesheet_digest)
      expect(response.body).to include(tenant.name)
      expect(response.body).not_to include(other_branding.stylesheet_digest)
      expect(response.body).not_to include("Barbearia do Zé")
    end

    it "renders the brand mark, the panel title and the establishment name" do
      mary = create(:tenant, name: "Mary Sombracelhas", subdomain: "mary-sombracelhas")
      create(:branding, tenant: mary, brand_600: "#8E4B6B")
      host! "mary-sombracelhas.zubio.com.br"

      get new_owner_session_path

      expect(response.body).to include("data-brand-initial")
      expect(response.body).to include(">M<")
      expect(response.body).to include("Entrar no painel")
      expect(response.body).to include("Mary Sombracelhas")
    end

    it "shows the logo in place of the initial when a logo is attached" do
      create(:branding, :with_logo, tenant: tenant)

      get new_owner_session_path

      expect(response.body).to include("<img")
      expect(response.body).not_to include("data-brand-initial")
    end

    it "keeps the password masked and the reveal button hidden without JavaScript" do
      get new_owner_session_path

      document = Nokogiri::HTML5(response.body)
      password_field = document.at_css("input[type='password']")
      toggle_button = document.at_css("button[data-password-visibility-target='toggle']")

      expect(password_field).not_to be_nil
      expect(toggle_button.has_attribute?("hidden")).to be(true)
    end

    it "links out to the platform login form for someone on the wrong establishment" do
      get new_owner_session_path

      document = Nokogiri::HTML5(response.body)
      link = document.at_css("a[href='#{new_login_link_url(host: Tenant::PLATFORM_HOST)}']")

      expect(response.body).to include("Não é este estabelecimento?")
      expect(link.text).to eq("zubio.com.br")
    end
  end

  describe "POST /owner/session" do
    it "creates a session and redirects to the dashboard with correct credentials" do
      owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")

      post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }

      expect(response).to redirect_to(owner_dashboard_path)
      expect(session[:user_id]).to eq(owner.id)
    end

    it "does not create a session with an incorrect password" do
      create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")

      post owner_session_path, params: { email: "owner@example.com", password: "wrong" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(session[:user_id]).to be_nil
    end

    it "does not authenticate credentials belonging to another tenant" do
      other_tenant = create(:tenant, subdomain: "other-salon")
      create(:user, tenant: other_tenant, email: "owner@example.com", password: "s3cr3t123")

      post owner_session_path, params: { email: "owner@example.com", password: "s3cr3t123" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(session[:user_id]).to be_nil
    end

    it "re-renders the login form with the typed email kept and the password cleared after a wrong password" do
      create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")

      post owner_session_path, params: { email: "owner@example.com", password: "wrong" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("E-mail ou senha inválidos.")
      expect(response.body).to include(%(value="owner@example.com"))
      expect(response.body).not_to include(%(value="wrong"))
    end

    it "does not leak another tenant's data when the same email fails on this host" do
      other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      branding = create(:branding, tenant: tenant, brand_600: "#4F46E5")
      other_branding = create(:branding, tenant: other_tenant, brand_600: "#DC2626")
      create(:user, tenant: other_tenant, email: "owner@example.com", password: "s3cr3t123")
      create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")

      post owner_session_path, params: { email: "owner@example.com", password: "wrong" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(branding.stylesheet_digest)
      expect(response.body).not_to include(other_branding.stylesheet_digest)
    end

    it "blocks further attempts after the rate limit is exceeded" do
      create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")

      10.times { post owner_session_path, params: { email: "owner@example.com", password: "wrong" } }
      post owner_session_path, params: { email: "owner@example.com", password: "wrong" }

      expect(response).to redirect_to(new_owner_session_path)
      expect(flash[:alert]).to eq("Muitas tentativas. Tente de novo em alguns minutos.")
    end
  end

  describe "DELETE /owner/session" do
    it "ends the session and requires login again for a protected route" do
      owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
      post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }

      delete owner_session_path
      get owner_dashboard_path

      expect(response).to redirect_to(new_owner_session_path)
    end
  end
end
