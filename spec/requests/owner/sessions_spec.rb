require "rails_helper"

RSpec.describe "Owner session", type: :request do
  let(:tenant) { create(:tenant, subdomain: "joes-barbershop") }

  before do
    host! "#{tenant.subdomain}.zubio.com.br"
    Rails.cache.clear
  end

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
