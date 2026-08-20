require "rails_helper"

RSpec.describe Tenant::CheckCustomDomainVerificationJob, type: :job do
  it "marks the tenant's custom domain verified when the hostname is active" do
    tenant = create(:tenant, :with_pending_custom_domain)
    stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames/cf-hostname-id")
      .to_return(status: 200, body: { result: { status: "active" } }.to_json, headers: { "Content-Type" => "application/json" })

    described_class.perform_now(tenant.id)

    expect(tenant.reload.custom_domain_verified_at).to be_present
  end

  it "reopens the tenant scope from the tenant_id argument, not from the caller's current tenant" do
    tenant_a = create(:tenant)
    tenant_b = create(:tenant, :with_pending_custom_domain)
    stub_request(:get, "https://api.cloudflare.com/client/v4/zones/#{ENV['CLOUDFLARE_ZONE_ID']}/custom_hostnames/cf-hostname-id")
      .to_return(status: 200, body: { result: { status: "active" } }.to_json, headers: { "Content-Type" => "application/json" })

    ActsAsTenant.with_tenant(tenant_a) { described_class.perform_now(tenant_b.id) }

    expect(tenant_b.reload.custom_domain_verified_at).to be_present
  end
end
