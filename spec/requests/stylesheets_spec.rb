require "rails_helper"

RSpec.describe "Generated stylesheets", type: :request do
  let(:outdated_safari) do
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15"
  end

  describe "GET /branding.css" do
    it "serves both ramps of the establishment in the host and never another one's" do
      aurora = create(:tenant, subdomain: "estudio-aurora")
      other = create(:tenant, subdomain: "salon-b")
      branding = create(:branding, tenant: aurora, brand_600: "#1D4ED8", brand_secondary_600: "#0B7658")
      create(:branding, tenant: other, brand_600: "#DC2626", brand_secondary_600: "#96590B")

      host! "estudio-aurora.zubio.com.br"
      get branding_stylesheet_path(v: branding.stylesheet_digest)

      expect(response.media_type).to eq("text/css")
      expect(response.body).to include("--brand-600:#1D4ED8;")
      expect(response.body).to include("--secondary-600:#0B7658;")
      expect(response.body).not_to include("#DC2626")
      expect(response.body).not_to include("#96590B")
    end

    it "serves the platform default at the platform root, where no establishment is resolved" do
      aurora = create(:tenant, subdomain: "estudio-aurora")
      create(:branding, tenant: aurora, brand_600: "#1D4ED8")

      host! "zubio.com.br"
      get branding_stylesheet_path(v: Branding.platform_default.stylesheet_digest)

      expect(response.body).to include("--brand-600:#{Branding::DEFAULT_BRAND_600};")
      expect(response.body).not_to include("--brand-600:#1D4ED8;")
    end

    it "falls back to the platform default when the establishment has no branding yet" do
      create(:tenant, subdomain: "no-branding-yet")

      host! "no-branding-yet.zubio.com.br"
      get branding_stylesheet_path(v: Branding.platform_default.stylesheet_digest)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("--brand-600:#{Branding::DEFAULT_BRAND_600};")
    end

    it "answers nothing for a host no establishment owns" do
      host! "does-not-exist.zubio.com.br"
      get branding_stylesheet_path(v: "no-such-digest")

      expect(response).to have_http_status(:not_found)
    end

    it "lets the sheet be cached forever when the URL carries the digest of what it serves" do
      tenant = create(:tenant, subdomain: "estudio-aurora")
      branding = create(:branding, tenant: tenant, brand_600: "#1D4ED8")

      host! "estudio-aurora.zubio.com.br"
      get branding_stylesheet_path(v: branding.stylesheet_digest)

      expect(response.headers["Cache-Control"]).to include("max-age=31536000")
      expect(response.headers["Cache-Control"]).to include("public")
    end

    it "refuses to be cached when the URL carries a version it no longer serves" do
      tenant = create(:tenant, subdomain: "estudio-aurora")
      create(:branding, tenant: tenant, brand_600: "#1D4ED8")

      host! "estudio-aurora.zubio.com.br"
      get branding_stylesheet_path(v: "stale-digest")

      expect(response.headers["Cache-Control"]).to include("no-cache")
      expect(response.body).to include("--brand-600:#1D4ED8;")
    end

    it "serves an outdated browser too, so the landing it paints never loses its colors" do
      host! "zubio.com.br"
      get branding_stylesheet_path(v: Branding.platform_default.stylesheet_digest),
        headers: { "User-Agent" => outdated_safari }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /showcase.css" do
    it "serves the demo ramps and never the tenant namespace" do
      host! "zubio.com.br"
      get showcase_stylesheet_path(v: Landing::ShowcaseBrand.stylesheet_digest)

      expect(response.media_type).to eq("text/css")
      expect(response.body).to include("--demo-600:#96590B;")
      expect(response.body).not_to include("--brand-600:")
    end

    it "lets the sheet be cached forever when the URL carries the digest of what it serves" do
      host! "zubio.com.br"
      get showcase_stylesheet_path(v: Landing::ShowcaseBrand.stylesheet_digest)

      expect(response.headers["Cache-Control"]).to include("max-age=31536000")
    end
  end

  describe "GET /palette.css" do
    it "serves one background rule per swatch of the brand palette" do
      host! "zubio.com.br"
      get palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)

      expect(response.media_type).to eq("text/css")
      expect(response.body).to include(%([data-swatch="#{Branding::Palette::FAMILIES.first}"]))
      expect(response.body).not_to include("--brand-600:")
    end

    it "lets the sheet be cached forever when the URL carries the digest of what it serves" do
      host! "zubio.com.br"
      get palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)

      expect(response.headers["Cache-Control"]).to include("max-age=31536000")
    end
  end
end
