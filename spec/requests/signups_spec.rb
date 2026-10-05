require "rails_helper"

RSpec.describe "Signup", type: :request do
  before { host! "zubio.com.br" }

  describe "GET /signup/new" do
    it "renders the signup form outside any tenant subdomain" do
      get new_signup_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Criar sua conta")
    end

    it "wraps the form in a panel landmark named by its own heading" do
      get new_signup_path

      expect(response.body).to include(%(<section aria-labelledby="#{Components::Panel::HEADING_ID}"))
      expect(response.body).to include(%(<h1 id="#{Components::Panel::HEADING_ID}"))
      expect(response.body).to include("Criar sua conta")
    end

    it "sends the acquisition funnel back to the platform host when reached on a tenant subdomain" do
      host! "joes-barbershop.zubio.com.br"

      get new_signup_path

      expect(response).to redirect_to(new_signup_url(host: Tenant::PLATFORM_HOST))
    end

    it "submits outside Turbo so the browser itself follows the cross-origin redirect" do
      get new_signup_path

      expect(response.body).to include(%(data-turbo="false"))
    end

    it "renders the platform header without the landing section nav" do
      get new_signup_path

      expect(response.body).to include(%(aria-label="Trocar o tema"))
      expect(response.body).not_to include("#como")
    end

    it "does not ask for an establishment name or a subdomain" do
      get new_signup_path

      expect(response.body).not_to include("Nome do estabelecimento")
      expect(response.body).not_to include("Subdomínio")
    end

    it "does not ask the visitor to confirm the password" do
      get new_signup_path

      expect(response.body).not_to include("Confirme a senha")
    end

    it "asks only for the person's name, email and password" do
      get new_signup_path

      expect(response.body).to include("Seu nome")
      expect(response.body).to include("E-mail")
      expect(response.body).to include("Senha")
    end

    it "states the minimum password length on the form before any error" do
      get new_signup_path

      expect(response.body).to include("Mínimo de 8 caracteres")
      expect(response.body).to include(%(minlength="8"))
    end
  end

  describe "POST /signup" do
    it "creates a nameless tenant with a provisional subdomain, its owner and professional" do
      post signup_path, params: { user: { name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123" } }

      owner = User.unscoped.sole
      tenant = owner.tenant
      expect(tenant.name).to be_nil
      expect(tenant).to be_active
      ActsAsTenant.with_tenant(tenant) { expect(tenant.users.sole).to be_owner }
      ActsAsTenant.with_tenant(tenant) { expect(Professional.sole.display_name).to eq("Ana Lima") }
    end

    it "hands the owner over to the provisional subdomain" do
      post signup_path, params: { user: { name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123" } }

      tenant = User.unscoped.sole.tenant
      expect(response.location).to start_with(owner_handoff_url(subdomain: tenant.subdomain))
    end

    it "creates the account with the single password the visitor typed, without confirmation" do
      post signup_path, params: { user: { name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123" } }

      owner = User.unscoped.sole
      expect(owner.authenticate("s3cr3t123")).to eq(owner)
    end

    it "rejects an invalid email and re-renders the form with the typed name kept" do
      post signup_path, params: { user: { name: "Ana Lima", email: "not-an-email", password: "s3cr3t123" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(%(value="Ana Lima"))
      expect(User.unscoped.count).to eq(0)
    end

    it "rejects a short password, keeps the account uncreated, and states the minimum by the password field" do
      post signup_path, params: { user: { name: "Ana Lima", email: "ana@example.com", password: "123" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("é muito curto (mínimo: 8 caracteres)")
      expect(User.unscoped.count).to eq(0)
      expect(Tenant.count).to eq(0)
    end

    it "accepts a password of the minimum length and hands the owner to onboarding" do
      post signup_path, params: { user: { name: "Ana Lima", email: "ana@example.com", password: "12345678" } }

      owner = User.unscoped.sole
      expect(owner.authenticate("12345678")).to eq(owner)
      expect(response.location).to start_with(owner_handoff_url(subdomain: owner.tenant.subdomain))
    end

    it "names blank fields in Portuguese, without the default English" do
      post signup_path, params: { user: { name: "", email: "", password: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("não pode ficar em branco")
      expect(response.body).not_to include("can't be blank")
    end

    it "states a malformed email in Portuguese, without the default English" do
      post signup_path, params: { user: { name: "Ana Lima", email: "not-an-email", password: "s3cr3t123" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("não é válido")
      expect(response.body).not_to include("is invalid")
    end

    it "blocks further signup attempts after the rate limit is exceeded" do
      5.times { |index| post signup_path, params: { user: { name: "Ana Lima", email: "ana#{index}@example.com", password: "s3cr3t123" } } }

      post signup_path, params: { user: { name: "Ana Lima", email: "ana-over@example.com", password: "s3cr3t123" } }

      expect(response).to redirect_to(new_signup_path)
    end

    it "tells the visitor to try again later once the rate limit is exceeded" do
      5.times { |index| post signup_path, params: { user: { name: "Ana Lima", email: "ana#{index}@example.com", password: "s3cr3t123" } } }

      post signup_path, params: { user: { name: "Ana Lima", email: "ana-over@example.com", password: "s3cr3t123" } }
      follow_redirect!

      expect(response.body).to include("Muitas tentativas. Tente novamente mais tarde.")
    end

    it "does not affect the existing tenant's owner or data when a new establishment signs up" do
      existing_tenant = create(:tenant, subdomain: "barbearia-do-ze")
      owner = create(:user, tenant: existing_tenant, email: "ze@example.com", password: "s3cr3t123")

      post signup_path, params: { user: { name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123" } }

      expect(User.unscoped.where(tenant: existing_tenant)).to contain_exactly(owner)
      expect(owner.reload.authenticate("s3cr3t123")).to eq(owner)
      expect(existing_tenant.reload.subdomain).to eq("barbearia-do-ze")
      expect(existing_tenant.status).to eq("active")
    end

    it "emails the new owner the provisional address" do
      perform_enqueued_jobs do
        post signup_path, params: { user: { name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123" } }
      end

      tenant = User.unscoped.sole.tenant
      delivery = ActionMailer::Base.deliveries.last
      expect(delivery.subject).to eq("Sua conta no Zubio está pronta")
      expect(delivery.body.to_s).to include(tenant.subdomain)
    end
  end
end
