require "rails_helper"

RSpec.describe "Landing page", type: :request do
  describe "GET / on the platform host" do
    before { host! "zubio.com.br" }

    it "renders the landing page with a call to action pointing at the signup form" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sua agenda online, com a sua marca")
      expect(response.body).to include(%(href="#{new_signup_path}"))
    end

    it "renders even when no tenant exists at all" do
      get root_path

      expect(Tenant.count).to eq(0)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET / on a tenant host" do
    it "redirects to the establishment entrance instead of rendering the landing page" do
      create(:tenant, subdomain: "estudio-aurora")

      host! "estudio-aurora.zubio.com.br"
      get root_path

      expect(response).to redirect_to(new_owner_session_path)
      expect(response.body).not_to include("Sua agenda online, com a sua marca")
    end

    it "returns 404 when the subdomain does not exist" do
      host! "estabelecimento-que-nao-existe.zubio.com.br"
      get root_path

      expect(response).to have_http_status(:not_found)
    end

    it "renders the establishment's own brand at its entrance and never another tenant's" do
      aurora = create(:tenant, subdomain: "estudio-aurora")
      ze = create(:tenant, subdomain: "barbearia-do-ze")
      create(:branding, tenant: aurora, brand_600: "#4F46E5")
      create(:branding, tenant: ze, brand_600: "#DC2626")

      host! "estudio-aurora.zubio.com.br"
      get root_path
      follow_redirect!

      expect(response.body).to include("--brand-600:#4F46E5;")
      expect(response.body).not_to include("--brand-600:#DC2626;")
    end
  end

  describe "GET / on the www host" do
    it "redirects permanently to the apex, which serves the landing page" do
      host! "www.zubio.com.br"
      get root_path

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("http://zubio.com.br/")
    end
  end

  describe "GET / from an outdated browser" do
    let(:outdated_safari) do
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15"
    end

    before { host! "zubio.com.br" }

    it "serves the landing page anyway" do
      get root_path, headers: { "User-Agent" => outdated_safari }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sua agenda online, com a sua marca")
    end

    it "still blocks the same browser on the signup form" do
      get new_signup_path, headers: { "User-Agent" => outdated_safari }

      expect(response).to have_http_status(:not_acceptable)
    end
  end
end
