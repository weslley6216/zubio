require "rails_helper"

RSpec.describe "Generated stylesheets", type: :request do
  let(:outdated_safari) do
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.3 Safari/605.1.15"
  end

  describe "GET /branding.css" do
    it "serves the brand ramp and the theme of the establishment in the host and never another one's" do
      ze = create(:tenant, subdomain: "barbearia-do-ze")
      other = create(:tenant, subdomain: "salon-b")
      branding = create(:branding, :with_background, tenant: ze)
      create(:branding, tenant: other, brand_600: "#DC2626")
      host! "barbearia-do-ze.zubio.com.br"

      get branding_stylesheet_path(v: branding.stylesheet_digest)

      expect(response.media_type).to eq("text/css")
      expect(response.body).to include("--brand-600:#F0617A;")
      expect(response.body).to include("--theme-bg:#16324A;")
      expect(response.body).to include("--theme-card:#e7f0f8;")
      expect(response.body).not_to include("#DC2626")
    end

    it "carries the eighteen theme tokens, every one a six-digit hex" do
      ze = create(:tenant, subdomain: "barbearia-do-ze")
      branding = create(:branding, :with_background, tenant: ze)
      host! "barbearia-do-ze.zubio.com.br"

      get branding_stylesheet_path(v: branding.stylesheet_digest)

      tokens = response.body.scan(/--theme-([\w-]+):([^;]+);/)

      expect(tokens.map(&:first)).to eq(%w[
        bg on-bg on-bg-muted bg-tint ghost danger-on-bg danger-line-on-bg
        card on-card on-card-muted card-line card-chip field-line focus
        danger-on-card accent on-accent selected-ring
      ])
      expect(tokens.map(&:last)).to all(match(/\A#\h{6}\z/))
      expect(response.body).not_to include("--secondary-")
    end

    it "derives no rule from a stored support color" do
      tenant = create(:tenant, subdomain: "estudio-aurora")
      branding = create(:branding, tenant: tenant, brand_600: "#2C6CB0", brand_secondary_600: "#E8493C")
      host! "estudio-aurora.zubio.com.br"

      get branding_stylesheet_path(v: branding.stylesheet_digest)

      body = response.body.downcase
      leaked = Branding::ColorScale.new("#E8493C").tokens.values.map(&:downcase).select { |hex| body.include?(hex) }

      expect(leaked).to be_empty
      expect(body).to include("--theme-accent:#2c6cb0;")
    end

    it "keeps another establishment's background out of the sheet" do
      ze = create(:tenant, subdomain: "barbearia-do-ze")
      create(:branding, :with_background, tenant: ze)
      mary = create(:tenant, subdomain: "mary-sombracelhas")
      mary_branding = create(:branding, tenant: mary, brand_600: "#8E4B6B")
      host! "mary-sombracelhas.zubio.com.br"

      get branding_stylesheet_path(v: mary_branding.stylesheet_digest)

      body = response.body.downcase
      leaked_background = Branding::ColorScale.new("#16324A").tokens.values.map(&:downcase)

      expect(body).not_to include("#16324a")
      expect(leaked_background.select { |hex| body.include?(hex) }).to be_empty
      expect(body).to include("--theme-bg:#f8fafb;")
      expect(body).to include("--theme-accent:#8e4b6b;")
    end

    it "serves the platform default at the platform root, where no establishment is resolved" do
      aurora = create(:tenant, subdomain: "estudio-aurora")
      create(:branding, tenant: aurora, brand_600: "#1D4ED8")
      host! "zubio.com.br"

      get branding_stylesheet_path(v: Branding.platform_default.stylesheet_digest)

      expect(response.body).to include("--brand-600:#{Branding::DEFAULT_BRAND_600};")
      expect(response.body).not_to include("--brand-600:#1D4ED8;")
      expect(response.body).to include("--theme-bg:#f8fafb;")
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
    it "serves one background rule per swatch of the brand palette and the preview ramps" do
      host! "zubio.com.br"

      get palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)

      expect(response.media_type).to eq("text/css")
      expect(response.body).to include(%([data-swatch="#{Branding::Palette::FAMILIES.first}"]))
      expect(response.body).to include(%([data-preview-brand="#{Branding::Palette::FAMILIES.first}"]{))
    end

    it "is built from the families alone and never carries a stored brand color" do
      tenant = create(:tenant, subdomain: "estudio-aurora")
      create(:branding, tenant: tenant, brand_600: "#123456")
      host! "estudio-aurora.zubio.com.br"

      get palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)

      expect(response.body).to eq(Branding::Palette.stylesheet)
      expect(response.body).not_to include("#123456")
    end

    it "lets the sheet be cached forever when the URL carries the digest of what it serves" do
      host! "zubio.com.br"

      get palette_stylesheet_path(v: Branding::Palette.stylesheet_digest)

      expect(response.headers["Cache-Control"]).to include("max-age=31536000")
    end
  end

  describe "GET /preview.css" do
    it "serves the brand ramp for a valid hex, public and cacheable" do
      host! "zubio.com.br"

      get "/preview.css", params: { brand: "#2C6CB0" }

      expect(response.media_type).to eq("text/css")
      expect(response.body).to include(%([data-preview-brand="#2C6CB0"]{))
      expect(response.headers["Cache-Control"]).to include("public")
      expect(response.headers["Cache-Control"]).to include("max-age=31536000")
    end

    it "serves the support ramp for a valid hex" do
      host! "zubio.com.br"

      get "/preview.css", params: { secondary: "#E8493C" }

      expect(response.body).to include(%([data-preview-secondary="#E8493C"]{))
    end

    it "answers not found when the code is not a color" do
      host! "zubio.com.br"

      get "/preview.css", params: { brand: "#ZZZ123" }

      expect(response).to have_http_status(:not_found)
    end

    it "answers not found and never echoes an injection payload" do
      host! "zubio.com.br"

      get "/preview.css", params: { brand: "#fff;}body{background:red" }

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("body{")
    end

    it "answers not found when no valid role is given" do
      host! "zubio.com.br"

      get "/preview.css"

      expect(response).to have_http_status(:not_found)
    end

    it "carries no establishment data and is identical on any host" do
      tenant = create(:tenant, subdomain: "estudio-aurora")
      create(:branding, tenant: tenant, brand_600: "#123456")
      host! "zubio.com.br"
      get "/preview.css", params: { brand: "#2C6CB0" }
      on_platform = response.body
      host! "estudio-aurora.zubio.com.br"

      get "/preview.css", params: { brand: "#2C6CB0" }

      expect(response.body).to eq(on_platform)
      expect(response.body).to include(%([data-preview-brand="#2C6CB0"]{))
      expect(response.body).not_to include("#123456")
    end
  end
end
