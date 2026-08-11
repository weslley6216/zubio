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

  it "delegates to the current tenant's cache_key_prefix" do
    tenant = create(:tenant, subdomain: "salon-a")
    branding = create(:branding, tenant: tenant)

    host! "salon-a.zubio.com.br"
    get "/cache_key_prefix_probe"

    expect(response.body).to eq("t/#{tenant.id}/#{branding.updated_at.to_i}")
  end
end
