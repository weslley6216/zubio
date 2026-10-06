require "rails_helper"

RSpec.describe "Application layout branding", type: :request do
  before do
    Rails.application.routes.draw do
      get "/layout_probe", to: "layout_probe#show"
      get "manifest.webmanifest" => "pwa#manifest", as: :pwa_manifest
      get "branding.css" => "stylesheets#branding", as: :branding_stylesheet
    end
  end

  after { Rails.application.reload_routes! }

  it "applies a stored theme choice before the stylesheet, so the page never flashes the other one" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")
    host! "joes-barbershop.zubio.com.br"

    get "/layout_probe"

    expect(response.body).to include(%(localStorage.getItem("theme")))
    expect(response.body.index("localStorage.getItem")).to be < response.body.index(%(rel="stylesheet"))
  end

  it "points at the tenant's brand as a sheet the browser fetches, never as inline style" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    branding = create(:branding, tenant: tenant, brand_600: "#4F46E5")
    host! "joes-barbershop.zubio.com.br"

    get "/layout_probe"

    expect(response.body).to include(%(href="/branding.css?v=#{branding.stylesheet_digest}"))
    expect(response.body).not_to include("<style")
  end

  it "marks the brand sheet as dynamic, which is what makes a Turbo visit swap it" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")
    host! "joes-barbershop.zubio.com.br"

    get "/layout_probe"

    expect(response.body).to include(%(<link rel="stylesheet" href="/branding.css))
    expect(response.body).to include(%(data-turbo-track="dynamic"))
  end

  it "points a tenant at its own brand sheet and not at another tenant's" do
    tenant = create(:tenant, subdomain: "salon-a")
    other_tenant = create(:tenant, subdomain: "salon-b")
    branding = create(:branding, tenant: tenant, brand_600: "#4F46E5")
    other_branding = create(:branding, tenant: other_tenant, brand_600: "#DC2626")
    host! "salon-a.zubio.com.br"

    get "/layout_probe"

    expect(response.body).to include(branding.stylesheet_digest)
    expect(response.body).not_to include(other_branding.stylesheet_digest)
  end

  it "falls back to the platform default sheet when the tenant has no branding" do
    create(:tenant, subdomain: "no-branding-yet")
    host! "no-branding-yet.zubio.com.br"

    get "/layout_probe"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(href="/branding.css?v=#{Branding.platform_default.stylesheet_digest}"))
  end

  it "never points at a sheet built from a brand_600 that fails validation" do
    tenant = create(:tenant, subdomain: "attacker")
    build(:branding, tenant: tenant, brand_600: "#4F46E5; } body { display:none } .x {").save
    host! "attacker.zubio.com.br"

    get "/layout_probe"

    expect(response.body).to include(%(href="/branding.css?v=#{Branding.platform_default.stylesheet_digest}"))
    expect(response.body).not_to include("display:none")
  end

  it "includes a theme-color meta tag matching the tenant's brand" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")
    host! "joes-barbershop.zubio.com.br"

    get "/layout_probe"

    expect(response.body).to include('<meta name="theme-color" content="#4F46E5">')
  end

  it "renders a single HTML document, with no Rails layout wrapping the Phlex view" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant)
    host! "joes-barbershop.zubio.com.br"

    get "/layout_probe"

    expect(response.body.scan("<html").size).to eq(1)
    expect(response.body).to start_with("<!doctype html>")
  end

  it "links to the tenant's manifest" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant)
    host! "joes-barbershop.zubio.com.br"

    get "/layout_probe"

    expect(response.body).to include('<link rel="manifest" href="/manifest.webmanifest">')
  end

  it "paints every page on the application surface, without each view opting in" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant)
    host! "joes-barbershop.zubio.com.br"

    get "/layout_probe"

    expect(response.body).to include(%(<html lang="pt-BR" class="bg-canvas text-ink [color-scheme:light_dark]">))
  end

  it "announces nothing to share when a view passes no social metadata, leaving the head as before" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant, brand_600: "#4F46E5")
    host! "joes-barbershop.zubio.com.br"

    get "/layout_probe"

    expect(response.body).to include('<meta name="theme-color" content="#4F46E5">')
    expect(Nokogiri::HTML5(response.body).css('meta[property^="og:"]')).to be_empty
  end
end
