require "rails_helper"

RSpec.describe "Tenant resolution by subdomain", type: :request do
  before do
    stub_const("TenantResolutionProbeController", Class.new(ApplicationController) do
      def show
        render plain: ActsAsTenant.current_tenant.subdomain
      end
    end)

    Rails.application.routes.draw do
      get "/tenant_resolution_probe", to: "tenant_resolution_probe#show"
    end
  end

  after { Rails.application.reload_routes! }

  it "populates the current tenant when the subdomain is valid" do
    create(:tenant, subdomain: "joes-barbershop")

    host! "joes-barbershop.zubio.com.br"
    get "/tenant_resolution_probe"

    expect(response).to have_http_status(:ok)
    expect(response.body).to eq("joes-barbershop")
  end

  it "returns 404 when the subdomain does not exist" do
    host! "does-not-exist.zubio.com.br"
    get "/tenant_resolution_probe"

    expect(response).to have_http_status(:not_found)
  end

  it "returns 404 when the tenant is suspended" do
    create(:tenant, subdomain: "suspended-tenant", status: "suspended")

    host! "suspended-tenant.zubio.com.br"
    get "/tenant_resolution_probe"

    expect(response).to have_http_status(:not_found)
  end
end
