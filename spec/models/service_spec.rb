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

  describe "name" do
    it "is invalid without a name" do
      service = build(:service, name: nil)

      service.valid?

      expect(service.errors[:name]).to be_present
    end

    it "is invalid when the tenant already has that name, ignoring case" do
      tenant = create(:tenant)
      create(:service, tenant: tenant, name: "Corte feminino")
      service = build(:service, tenant: tenant, name: "corte feminino")

      service.valid?

      expect(service.errors.details[:name]).to include(hash_including(error: :taken))
    end

    it "is valid when another tenant already has that name" do
      create(:service, tenant: create(:tenant), name: "Corte")
      service = build(:service, tenant: create(:tenant), name: "Corte")

      expect(service).to be_valid
    end
  end

  describe "duration_minutes" do
    it "is invalid when the duration is zero" do
      service = build(:service, duration_minutes: 0)

      service.valid?

      expect(service.errors[:duration_minutes]).to be_present
    end

    it "is invalid when the duration is not a multiple of five" do
      service = build(:service, duration_minutes: 7)

      service.valid?

      expect(service.errors[:duration_minutes]).to be_present
    end

    it "is invalid when the duration is above the maximum" do
      service = build(:service, duration_minutes: 600)

      service.valid?

      expect(service.errors[:duration_minutes]).to be_present
    end

    it "is valid at a multiple of five inside the range" do
      service = build(:service, duration_minutes: 45)

      expect(service).to be_valid
    end
  end

  describe "price_cents" do
    it "is invalid without a price" do
      service = build(:service, price_cents: nil)

      service.valid?

      expect(service.errors[:price_cents]).to be_present
    end

    it "is invalid with a negative price" do
      service = build(:service, price_cents: -1)

      service.valid?

      expect(service.errors[:price_cents]).to be_present
    end

    it "is valid with a price of zero" do
      service = build(:service, price_cents: 0)

      expect(service).to be_valid
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
