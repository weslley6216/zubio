require "rails_helper"

RSpec.describe "Content Security Policy", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }

  def nonce_from(response)
    response.headers["Content-Security-Policy"][/script-src [^;]*'nonce-([^']+)'/, 1]
  end

  def sign_in
    host! "#{tenant.subdomain}.zubio.com.br"
    post owner_session_path, params: { email: owner.email, password: "s3cr3t123" }
  end

  describe "a panel response" do
    it "carries an enforcing policy, not a report-only one" do
      create(:branding, tenant: tenant)
      sign_in

      get owner_dashboard_path

      expect(response.headers["Content-Security-Policy-Report-Only"]).to be_nil
      expect(response.headers["Content-Security-Policy"]).to include("default-src 'self'")
      expect(response.headers["Content-Security-Policy"]).to include("style-src-attr 'none'")
    end

    it "gives the layout's inline script and inline styles the nonce it announced" do
      create(:branding, tenant: tenant)
      sign_in

      get owner_dashboard_path

      nonce = nonce_from(response)
      expect(nonce).to be_present
      expect(response.body.scan(%(nonce="#{nonce}")).size).to be >= 2
    end
  end

  describe "the platform root, where no tenant is resolved" do
    before { host! Tenant::PLATFORM_HOST }

    it "carries the policy too" do
      get root_path

      expect(response.headers["Content-Security-Policy"]).to include("style-src 'self'")
      expect(response.body).to include(%(nonce="#{nonce_from(response)}"))
    end

    it "mints a different nonce for every response" do
      get root_path
      first = nonce_from(response)

      get root_path

      expect(nonce_from(response)).not_to eq(first)
    end
  end
end
