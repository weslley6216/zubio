require "rails_helper"

RSpec.describe "Signup", type: :request do
  before { host! "zubio.com.br" }

  def signup_params(name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123")
    { user: { name: name, email: email, password: password } }
  end

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
  end

  describe "POST /signup" do
    it "creates a nameless tenant with a provisional subdomain, its owner and professional" do
      post signup_path, params: signup_params

      owner = User.unscoped.sole
      tenant = owner.tenant

      expect(tenant.name).to be_nil
      expect(tenant).to be_active
      ActsAsTenant.with_tenant(tenant) { expect(tenant.users.sole).to be_owner }
      ActsAsTenant.with_tenant(tenant) { expect(Professional.sole.display_name).to eq("Ana Lima") }
    end

    it "hands the owner over to the provisional subdomain" do
      post signup_path, params: signup_params

      tenant = User.unscoped.sole.tenant

      expect(response.location).to start_with(owner_handoff_url(subdomain: tenant.subdomain))
    end

    it "creates the account with the single password the visitor typed, without confirmation" do
      post signup_path, params: signup_params(password: "s3cr3t123")

      owner = User.unscoped.sole

      expect(owner.authenticate("s3cr3t123")).to eq(owner)
    end

    it "blocks further signup attempts after the rate limit is exceeded" do
      5.times { |index| post signup_path, params: signup_params(email: "ana#{index}@example.com") }
      post signup_path, params: signup_params(email: "ana-over@example.com")

      expect(response).to redirect_to(new_signup_path)

      follow_redirect!

      expect(response.body).to include("Muitas tentativas. Tente novamente mais tarde.")
    end

    it "does not affect the existing tenant's owner or data when a new establishment signs up" do
      existing_tenant = create(:tenant, subdomain: "barbearia-do-ze")
      owner = create(:user, tenant: existing_tenant, email: "ze@example.com", password: "s3cr3t123")

      post signup_path, params: signup_params

      host! "#{existing_tenant.subdomain}.zubio.com.br"
      post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
      get owner_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(User.unscoped.where(tenant: existing_tenant).count).to eq(1)
    end

    it "emails the new owner the provisional address" do
      perform_enqueued_jobs do
        post signup_path, params: signup_params
      end

      tenant = User.unscoped.sole.tenant
      delivery = ActionMailer::Base.deliveries.last

      expect(delivery.subject).to eq("Sua conta no Zubio está pronta")
      expect(delivery.body.to_s).to include(tenant.subdomain)
    end
  end
end
