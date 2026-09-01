require "rails_helper"

RSpec.describe "Landing page", type: :request do
  describe "GET / on the platform host" do
    before { host! "zubio.com.br" }

    it "renders the landing page with a call to action pointing at the signup form" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sua marca, seu link,")
      expect(response.body).to include(%(href="#{new_signup_path}"))
    end

    it "renders the value proposition and the primary signup call to action" do
      get root_path

      expect(response.body).to include("Sua marca, seu link,")
      expect(response.body).to include("seu app")
      expect(response.body).to include(%(id="hero-cta"))
    end

    it "renders showcase palettes under the demo namespace, never the tenant namespace" do
      get root_path

      expect(response.body).to include("--demo-600:#96590B;")
      expect(response.body).not_to include("--brand-600:#96590B;")
    end

    it "renders even when no tenant exists at all" do
      get root_path

      expect(Tenant.count).to eq(0)
      expect(response).to have_http_status(:ok)
    end

    it "never renders any tenant's brand at the platform root" do
      aurora_studio = create(:tenant, subdomain: "aurora-studio")
      joes_barbershop = create(:tenant, subdomain: "joes-barbershop")
      create(:branding, tenant: aurora_studio, brand_600: "#1D4ED8")
      create(:branding, tenant: joes_barbershop, brand_600: "#DC2626")

      get root_path

      expect(response.body).to include("--brand-600:#{Branding::DEFAULT_BRAND_600};")
      expect(response.body).not_to include("--brand-600:#1D4ED8;")
      expect(response.body).not_to include("--brand-600:#DC2626;")
    end
  end

  describe "GET / on a tenant host" do
    it "redirects to the establishment entrance instead of rendering the landing page" do
      create(:tenant, subdomain: "aurora-studio")

      host! "aurora-studio.zubio.com.br"
      get root_path
      follow_redirect!

      expect(request.path).to eq(new_owner_session_path)
      expect(response.body).to include("Entrar")
      expect(response.body).not_to include("Sua marca, seu link,")
    end

    it "returns 404 when the subdomain does not exist" do
      host! "does-not-exist.zubio.com.br"
      get root_path

      expect(response).to have_http_status(:not_found)
    end

    it "renders the establishment's own brand at its entrance and never another tenant's" do
      aurora_studio = create(:tenant, subdomain: "aurora-studio")
      joes_barbershop = create(:tenant, subdomain: "joes-barbershop")
      create(:branding, tenant: aurora_studio, brand_600: "#1D4ED8")
      create(:branding, tenant: joes_barbershop, brand_600: "#DC2626")

      host! "aurora-studio.zubio.com.br"
      get root_path
      follow_redirect!

      expect(response.body).to include("--brand-600:#1D4ED8;")
      expect(response.body).not_to include("--brand-600:#DC2626;")
      expect(response.body).not_to include("--brand-600:#{Branding::DEFAULT_BRAND_600};")
    end
  end

  describe "GET / on the www host" do
    it "redirects permanently to the apex, which serves the landing page" do
      host! "www.zubio.com.br"
      get root_path

      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to("http://zubio.com.br/")
    end

    it "preserves the query string so campaign attribution survives the redirect" do
      host! "www.zubio.com.br"
      get root_path, params: { utm_source: "instagram", utm_campaign: "launch" }

      expect(response).to have_http_status(:moved_permanently)
      expect(response.location).to start_with("http://zubio.com.br/?")
      expect(response.location).to include("utm_source=instagram")
      expect(response.location).to include("utm_campaign=launch")
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
      expect(response.body).to include("Sua marca, seu link,")
    end

    it "still blocks the same browser on the signup form" do
      get new_signup_path, headers: { "User-Agent" => outdated_safari }

      expect(response).to have_http_status(:not_acceptable)
    end
  end
end
