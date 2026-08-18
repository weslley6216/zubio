require "rails_helper"

RSpec.describe "Signup", type: :request do
  before { host! "zubio.com.br" }

  def signup_params(subdomain:, password: "s3cr3t123", password_confirmation: "s3cr3t123")
    {
      tenant: { name: "Studio Aurora", subdomain: subdomain },
      user: { name: "Ana Lima", email: "ana@example.com", password: password, password_confirmation: password_confirmation }
    }
  end

  describe "GET /signup/new" do
    it "renders the signup form outside any tenant subdomain" do
      get new_signup_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Criar sua conta")
    end
  end

  describe "POST /signup" do
    it "creates the tenant and its owner, then redirects to login on the new subdomain" do
      post signup_path, params: signup_params(subdomain: "estudio-aurora")

      tenant = Tenant.find_by(subdomain: "estudio-aurora")

      expect(tenant).to be_active
      expect(tenant.users.sole).to be_owner
      expect(response).to redirect_to(new_owner_session_url(subdomain: "estudio-aurora"))
    end

    it "rejects signup when the subdomain is already in use" do
      create(:tenant, subdomain: "estudio-aurora")

      expect {
        post signup_path, params: signup_params(subdomain: "estudio-aurora")
      }.to change(Tenant, :count).by(0).and change(User, :count).by(0)

      expect(response.body).to include("has already been taken")
    end

    it "rejects signup when the subdomain is reserved" do
      post signup_path, params: signup_params(subdomain: "admin")

      expect(response.body).to include("is reserved")
    end

    it "rejects signup when the password confirmation does not match" do
      post signup_path, params: signup_params(subdomain: "estudio-aurora", password: "s3cr3t123", password_confirmation: "different")

      expect(response.body).to include("doesn&#39;t match Password")
    end

    it "blocks further signup attempts after the rate limit is exceeded" do
      5.times { post signup_path, params: signup_params(subdomain: "estudio-aurora") }
      post signup_path, params: signup_params(subdomain: "estudio-aurora")

      expect(response).to redirect_to(new_signup_path)

      follow_redirect!

      expect(response.body).to include("Muitas tentativas. Tente novamente mais tarde.")
    end

    it "does not affect the existing tenant's owner or data when a new establishment signs up" do
      existing_tenant = create(:tenant, subdomain: "barbearia-do-ze")
      owner = create(:user, tenant: existing_tenant, email: "ze@example.com", password: "s3cr3t123")

      post signup_path, params: signup_params(subdomain: "estudio-aurora")

      host! "#{existing_tenant.subdomain}.zubio.com.br"
      post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
      get owner_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(User.unscoped.where(tenant: existing_tenant).count).to eq(1)
    end
  end
end
