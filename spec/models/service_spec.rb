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

    it "is invalid one step above the longest duration" do
      service = build(:service, duration_minutes: 485)

      service.valid?

      expect(service.errors[:duration_minutes]).to be_present
    end

    it "is valid at the shortest duration the business allows" do
      service = build(:service, duration_minutes: 5)

      expect(service).to be_valid
    end

    it "is valid at the longest duration the business allows" do
      service = build(:service, duration_minutes: 480)

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

  describe ".active" do
    it "excludes services that are not active" do
      tenant = create(:tenant)
      inactive = create(:service, tenant: tenant, active: false)

      result = ActsAsTenant.with_tenant(tenant) { Service.active }

      expect(result).not_to include(inactive)
    end

    it "returns only the active services of the tenant" do
      tenant = create(:tenant)
      service = create(:service, tenant: tenant)
      create(:service, tenant: tenant, active: false)

      result = ActsAsTenant.with_tenant(tenant) { Service.active }

      expect(result).to contain_exactly(service)
    end
  end

  describe ".ordered" do
    it "returns the services by name" do
      tenant = create(:tenant)
      create(:service, tenant: tenant, name: "Corte")
      create(:service, tenant: tenant, name: "Barba")

      result = ActsAsTenant.with_tenant(tenant) { Service.ordered }

      expect(result.map(&:name)).to eq([ "Barba", "Corte" ])
    end

    it "puts an accented name in its alphabetical place, not after Z" do
      tenant = create(:tenant)
      create(:service, tenant: tenant, name: "Zebra")
      create(:service, tenant: tenant, name: "Água")
      create(:service, tenant: tenant, name: "Barba")

      result = ActsAsTenant.with_tenant(tenant) { Service.ordered }

      expect(result.map(&:name)).to eq([ "Água", "Barba", "Zebra" ])
    end
  end

  describe "#price" do
    it "converts cents into reais as a decimal" do
      service = build(:service, price_cents: 9_000)

      expect(service.price).to eq(BigDecimal("90"))
    end

    it "keeps money out of floating point" do
      service = build(:service, price_cents: 9_999)

      expect(service.price).to be_a(BigDecimal)
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
