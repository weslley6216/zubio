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

    it "renders the alert message after an invalid login attempt" do
      create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
      post owner_session_path, params: { email: "owner@example.com", password: "wrong" }

      get new_owner_session_path

      expect(response.body).to include("E-mail ou senha inválidos.")
      expect(response.body).to include(%(class="mb-4 rounded-md bg-danger-surface px-4 py-2 text-sm text-danger"))
    end

    it "renders no platform chrome on the tenant's own host" do
      create(:branding, tenant: tenant, brand_600: "#4F46E5")

      get new_owner_session_path

      expect(response.body).to include("--brand-600:#4F46E5;")
      expect(response.body).not_to include(%(aria-label="Trocar o tema"))
    end

    it "renders the brand of the tenant in the host and nothing of another tenant" do
      other_tenant = create(:tenant, subdomain: "salon-b", name: "Barbearia do Zé")
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      create(:branding, tenant: other_tenant, brand_600: "#DC2626")

      get new_owner_session_path

      expect(response.body).to include("--brand-600:#4F46E5;")
      expect(response.body).not_to include("--brand-600:#DC2626;")
      expect(response.body).not_to include("Barbearia do Zé")
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

      expect(response).to redirect_to(new_owner_session_path)
      expect(session[:user_id]).to be_nil
    end

    it "does not authenticate credentials belonging to another tenant" do
      other_tenant = create(:tenant, subdomain: "other-salon")
      create(:user, tenant: other_tenant, email: "owner@example.com", password: "s3cr3t123")

      post owner_session_path, params: { email: "owner@example.com", password: "s3cr3t123" }

      expect(response).to redirect_to(new_owner_session_path)
      expect(session[:user_id]).to be_nil
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
