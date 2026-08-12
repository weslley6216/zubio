require "rails_helper"

RSpec.describe "Application layout branding", type: :request do
  before do
    stub_const("LayoutProbeController", Class.new(ApplicationController) do
      def show
        branding = ActsAsTenant.current_tenant.branding || Branding.platform_default
        render Views::Layouts::Application.new(title: "Zubio", branding: branding)
      end
    end)

    Rails.application.routes.draw do
      get "/layout_probe", to: "layout_probe#show"
      # pwa_manifest_path is needed here because Rails.application.routes.draw
      # replaces the whole route set, and the layout under test links to it.
      get "manifest.webmanifest" => "pwa#manifest", as: :pwa_manifest
    end
  end

  after { Rails.application.reload_routes! }

  it "renders the tenant's brand color as a CSS custom property" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")

    host! "joes-barbershop.zubio.com.br"
    get "/layout_probe"

    expect(response.body).to include("--brand-600:#4F46E5;")
  end

  it "renders distinct palettes for two different tenants" do
    tenant_a = create(:tenant, subdomain: "salon-a")
    tenant_b = create(:tenant, subdomain: "salon-b")
    create(:branding, tenant: tenant_a, brand_600: "#4F46E5")
    create(:branding, tenant: tenant_b, brand_600: "#DC2626")

    host! "salon-a.zubio.com.br"
    get "/layout_probe"
    body_a = response.body

    host! "salon-b.zubio.com.br"
    get "/layout_probe"
    body_b = response.body

    expect(body_a).to include("--brand-600:#4F46E5;")
    expect(body_b).to include("--brand-600:#DC2626;")
  end

  it "falls back to the platform default palette when the tenant has no branding" do
    create(:tenant, subdomain: "no-branding-yet")

    host! "no-branding-yet.zubio.com.br"
    get "/layout_probe"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("--brand-600:#{Branding::DEFAULT_BRAND_600};")
  end

  it "never persists or renders a brand_600 that fails validation" do
    tenant = create(:tenant, subdomain: "attacker")
    branding = build(:branding, tenant: tenant, brand_600: "#4F46E5; } body { display:none } .x {")

    expect(branding.save).to be false

    host! "attacker.zubio.com.br"
    get "/layout_probe"

    expect(response.body).not_to include("display:none")
    expect(response.body).to include("--brand-600:#{Branding::DEFAULT_BRAND_600};")
  end

  it "includes a theme-color meta tag matching the tenant's brand" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")

    host! "joes-barbershop.zubio.com.br"
    get "/layout_probe"

    expect(response.body).to include('<meta name="theme-color" content="#4F46E5">')
  end

  it "links to the tenant's manifest" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant)

    host! "joes-barbershop.zubio.com.br"
    get "/layout_probe"

    expect(response.body).to include('<link rel="manifest" href="/manifest.webmanifest">')
  end
end
