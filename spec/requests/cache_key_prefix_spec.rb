require "rails_helper"

RSpec.describe "Cache key prefix", type: :request do
  before do
    stub_const("CacheKeyPrefixProbeController", Class.new(ApplicationController) do
      def show
        render plain: cache_key_prefix
      end
    end)

    Rails.application.routes.draw do
      get "/cache_key_prefix_probe", to: "cache_key_prefix_probe#show"
    end
  end

  after { Rails.application.reload_routes! }

  it "includes the tenant id and the branding's updated_at timestamp" do
    tenant = create(:tenant, subdomain: "salon-a")
    branding = create(:branding, tenant: tenant)

    host! "salon-a.zubio.com.br"
    get "/cache_key_prefix_probe"

    expect(response.body).to eq("t/#{tenant.id}/#{branding.updated_at.to_i}")
  end

  it "omits the timestamp when the tenant has no branding" do
    tenant = create(:tenant, subdomain: "no-branding")

    host! "no-branding.zubio.com.br"
    get "/cache_key_prefix_probe"

    expect(response.body).to eq("t/#{tenant.id}/")
  end

  it "differs between tenants" do
    tenant_a = create(:tenant, subdomain: "salon-a")
    tenant_b = create(:tenant, subdomain: "salon-b")

    host! "salon-a.zubio.com.br"
    get "/cache_key_prefix_probe"
    prefix_a = response.body

    host! "salon-b.zubio.com.br"
    get "/cache_key_prefix_probe"
    prefix_b = response.body

    expect(prefix_a).not_to eq(prefix_b)
  end

  it "changes when the tenant's branding is updated" do
    tenant = create(:tenant, subdomain: "salon-a")
    branding = create(:branding, tenant: tenant)

    host! "salon-a.zubio.com.br"
    get "/cache_key_prefix_probe"
    prefix_before = response.body

    branding.update_column(:updated_at, branding.updated_at + 1.hour)
    get "/cache_key_prefix_probe"

    expect(response.body).not_to eq(prefix_before)
  end
end
