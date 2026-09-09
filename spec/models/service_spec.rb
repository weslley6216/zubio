require "rails_helper"

RSpec.describe Service, type: :model do
  describe "creation" do
    it "belongs to the current tenant when created inside its scope" do
      tenant = create(:tenant)

      service = ActsAsTenant.with_tenant(tenant) { Service.create!(name: "Corte feminino", duration_minutes: 45, price_cents: 9_000) }

      expect(service.tenant).to eq(tenant)
    end

    it "is active when created" do
      service = create(:service)

      expect(service).to be_active
    end
  end

  describe "tenant isolation" do
    it "does not include services from another tenant" do
      tenant_a = create(:tenant)
      tenant_b = create(:tenant)
      create(:service, tenant: tenant_a)

      result = ActsAsTenant.with_tenant(tenant_b) { Service.all }

      expect(result).to be_empty
    end

    it "includes the service from its own tenant" do
      tenant = create(:tenant)
      service = create(:service, tenant: tenant)

      result = ActsAsTenant.with_tenant(tenant) { Service.all }

      expect(result).to include(service)
    end
  end
end
