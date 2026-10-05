require "rails_helper"

RSpec.describe "PWA manifest", type: :request do
  describe "GET /manifest.webmanifest" do
    it "returns the tenant's brand as name and theme_color with the manifest content-type" do
      tenant = create(:tenant, subdomain: "joes-barbershop", name: "Joe's Barbershop")
      create(:branding, tenant: tenant, brand_600: "#4F46E5")
      host! "joes-barbershop.zubio.com.br"

      get "/manifest.webmanifest"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/manifest+json")
      expect(JSON.parse(response.body)["name"]).to eq("Joe's Barbershop")
      expect(JSON.parse(response.body)["theme_color"]).to eq("#4F46E5")
    end

    it "produces a distinct id for each tenant so installs don't collide" do
      create(:branding, tenant: create(:tenant, subdomain: "salon-a"))
      create(:branding, tenant: create(:tenant, subdomain: "salon-b"))
      host! "salon-a.zubio.com.br"
      get "/manifest.webmanifest"
      salon_a_id = JSON.parse(response.body)["id"]
      host! "salon-b.zubio.com.br"

      get "/manifest.webmanifest"

      expect(JSON.parse(response.body)["id"]).to be_present
      expect(JSON.parse(response.body)["id"]).not_to eq(salon_a_id)
    end

    it "lists 192x192 and 512x512 icons plus a maskable icon, all from active storage, when the tenant has a logo" do
      create(:branding, :with_logo, tenant: create(:tenant, subdomain: "with-logo"))
      host! "with-logo.zubio.com.br"

      get "/manifest.webmanifest"

      icons = JSON.parse(response.body)["icons"]
      expect(icons.map { |icon| [ icon["sizes"], icon["purpose"] ] }).to contain_exactly(
        [ "192x192", "any" ],
        [ "512x512", "any" ],
        [ "512x512", "maskable" ]
      )
      expect(icons.map { |icon| icon["src"] }).to all(start_with("/rails/active_storage/"))
    end

    it "serves every listed icon same-origin" do
      create(:branding, :with_logo, tenant: create(:tenant, subdomain: "with-logo"))
      host! "with-logo.zubio.com.br"
      get "/manifest.webmanifest"
      icon_sources = JSON.parse(response.body)["icons"].map { |icon| icon["src"] }

      statuses = icon_sources.map do |icon_source|
        get icon_source
        response.status
      end

      expect(statuses).to all(eq(200))
    end

    it "falls back to the platform icon when the tenant has no logo, and stays installable" do
      tenant = create(:tenant, subdomain: "no-logo")
      create(:branding, tenant: tenant)
      host! "no-logo.zubio.com.br"

      get "/manifest.webmanifest"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["icons"]).to all(include("src" => "/icon.png"))
    end

    it "returns 404 for a subdomain with no tenant" do
      host! "does-not-exist.zubio.com.br"

      get "/manifest.webmanifest"

      expect(response).to have_http_status(:not_found)
    end

    describe "tenant isolation" do
      it "resolves the manifest icons to the tenant's own logo blob" do
        earlier_tenant = create(:tenant, subdomain: "earlier-tenant")
        own_tenant = create(:tenant, subdomain: "own-tenant")
        create(:branding, :with_logo, tenant: earlier_tenant)
        own_branding = create(:branding, :with_logo, tenant: own_tenant)
        host! "own-tenant.zubio.com.br"

        get "/manifest.webmanifest"

        icon_source = JSON.parse(response.body)["icons"].first["src"]
        expect(ActiveStorage::Blob.find_signed!(icon_source[%r{/representations/proxy/([^/]+)/}, 1])).to eq(own_branding.logo.blob)
      end

      it "never resolves the manifest icons to another tenant's logo blob" do
        tenant_a = create(:tenant, subdomain: "tenant-a")
        tenant_b = create(:tenant, subdomain: "tenant-b")
        create(:branding, :with_logo, tenant: tenant_a)
        other_branding = create(:branding, :with_logo, tenant: tenant_b)
        host! "tenant-a.zubio.com.br"

        get "/manifest.webmanifest"

        icon_source = JSON.parse(response.body)["icons"].first["src"]
        expect(ActiveStorage::Blob.find_signed!(icon_source[%r{/representations/proxy/([^/]+)/}, 1])).not_to eq(other_branding.logo.blob)
      end
    end
  end
end
