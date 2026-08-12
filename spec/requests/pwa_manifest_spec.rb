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

      body = JSON.parse(response.body)
      expect(body["name"]).to eq("Joe's Barbershop")
      expect(body["theme_color"]).to eq("#4F46E5")
    end

    it "produces a distinct id for each tenant so installs don't collide" do
      tenant_a = create(:tenant, subdomain: "salon-a")
      tenant_b = create(:tenant, subdomain: "salon-b")
      create(:branding, tenant: tenant_a)
      create(:branding, tenant: tenant_b)

      host! "salon-a.zubio.com.br"
      get "/manifest.webmanifest"
      id_a = JSON.parse(response.body)["id"]

      host! "salon-b.zubio.com.br"
      get "/manifest.webmanifest"
      id_b = JSON.parse(response.body)["id"]

      expect(id_a).not_to eq(id_b)
    end

    it "lists 192x192 and 512x512 icons plus a maskable icon, all served same-origin, when the tenant has a logo" do
      tenant = create(:tenant, subdomain: "with-logo")
      create(:branding, :with_logo, tenant: tenant)

      host! "with-logo.zubio.com.br"
      get "/manifest.webmanifest"

      icons = JSON.parse(response.body)["icons"]
      sizes_and_purposes = icons.map { |icon| [ icon["sizes"], icon["purpose"] ] }
      expect(sizes_and_purposes).to contain_exactly(
        [ "192x192", "any" ],
        [ "512x512", "any" ],
        [ "512x512", "maskable" ]
      )

      icons.each do |icon|
        expect(icon["src"]).to start_with("/rails/active_storage/")

        get icon["src"]
        expect(response).to have_http_status(:ok)
      end
    end

    it "falls back to the platform icon when the tenant has no logo, and stays installable" do
      tenant = create(:tenant, subdomain: "no-logo")
      create(:branding, tenant: tenant)

      host! "no-logo.zubio.com.br"
      get "/manifest.webmanifest"

      expect(response).to have_http_status(:ok)
      icons = JSON.parse(response.body)["icons"]
      expect(icons).to all(include("src" => "/icon.png"))
    end

    it "returns 404 for a subdomain with no tenant" do
      host! "does-not-exist.zubio.com.br"
      get "/manifest.webmanifest"

      expect(response).to have_http_status(:not_found)
    end
  end
end
