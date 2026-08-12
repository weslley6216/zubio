require "rails_helper"

RSpec.describe Branding::PrecomputeIconVariantsJob, type: :job do
  it "processes each icon variant for the given tenant's branding" do
    tenant = create(:tenant)
    branding = create(:branding, :with_logo, tenant: tenant)

    described_class.perform_now(tenant.id)

    expect(branding.icon_variants.map { |entry| entry[:variant].image }).to all(be_present)
  end

  it "reopens the tenant scope from the tenant_id argument, not from the caller's current tenant" do
    tenant_a = create(:tenant)
    tenant_b = create(:tenant)
    branding_b = create(:branding, :with_logo, tenant: tenant_b)

    ActsAsTenant.with_tenant(tenant_a) { described_class.perform_now(tenant_b.id) }

    expect(branding_b.icon_variants.map { |entry| entry[:variant].image }).to all(be_present)
  end
end
