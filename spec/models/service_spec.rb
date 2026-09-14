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
    it "is invalid without a name, asking for one" do
      service = build(:service, name: nil)

      service.valid?

      expect(service.errors[:name]).to eq([ Service::NAME_REQUIRED_MESSAGE ])
    end

    it "is invalid when the tenant already has that name, ignoring case" do
      tenant = create(:tenant)
      create(:service, tenant: tenant, name: "Corte feminino")
      service = build(:service, tenant: tenant, name: "corte feminino")

      service.valid?

      expect(service.errors.details[:name]).to include(hash_including(error: :taken))
      expect(service.errors[:name]).to eq([ Service::NAME_TAKEN_MESSAGE ])
    end

    it "is invalid when the tenant already has that name and a stray space trails the new one" do
      tenant = create(:tenant)
      create(:service, tenant: tenant, name: "Corte feminino")
      service = build(:service, tenant: tenant, name: "Corte feminino ")

      service.valid?

      expect(service.errors[:name]).to eq([ Service::NAME_TAKEN_MESSAGE ])
    end

    it "is valid when another tenant already has that name" do
      create(:service, tenant: create(:tenant), name: "Corte")
      service = build(:service, tenant: create(:tenant), name: "Corte")

      expect(service).to be_valid
    end

    it "squeezes stray spaces out of the name" do
      service = build(:service, name: "  Corte   feminino ")

      expect(service.name).to eq("Corte feminino")
    end

    it "is invalid one character above the longest name" do
      service = build(:service, name: "a" * (Service::NAME_MAX_LENGTH + 1))

      service.valid?

      expect(service.errors[:name]).to eq([ Service::NAME_TOO_LONG_MESSAGE ])
    end

    it "is valid at the longest name" do
      service = build(:service, name: "a" * Service::NAME_MAX_LENGTH)

      expect(service).to be_valid
    end
  end

  describe "description" do
    it "is valid without a description" do
      service = build(:service, description: nil)

      expect(service).to be_valid
    end

    it "trims the spaces around the description" do
      service = build(:service, description: "  Inclui lavagem e finalização.  ")

      expect(service.description).to eq("Inclui lavagem e finalização.")
    end

    it "stores a blank description as none" do
      service = build(:service, description: "   ")

      expect(service.description).to be_nil
    end

    it "is invalid one character above the longest description" do
      service = build(:service, description: "a" * (Service::DESCRIPTION_MAX_LENGTH + 1))

      service.valid?

      expect(service.errors[:description]).to eq([ Service::DESCRIPTION_TOO_LONG_MESSAGE ])
    end

    it "is valid at the longest description" do
      service = build(:service, description: "a" * Service::DESCRIPTION_MAX_LENGTH)

      expect(service).to be_valid
    end
  end

  describe "duration_minutes" do
    it "is invalid when the duration is zero" do
      service = build(:service, duration_minutes: 0)

      service.valid?

      expect(service.errors[:duration_minutes]).to be_present
    end

    it "is invalid when the duration is not a multiple of five, naming the rule" do
      service = build(:service, duration_minutes: 7)

      service.valid?

      expect(service.errors[:duration_minutes]).to eq([ Service::DURATION_OUT_OF_STEP_MESSAGE ])
    end

    it "is invalid one step above the longest duration" do
      service = build(:service, duration_minutes: 485)

      service.valid?

      expect(service.errors[:duration_minutes]).to be_present
    end

    it "is invalid when the duration carries a fraction" do
      service = build(:service, duration_minutes: "45.5")

      service.valid?

      expect(service.errors[:duration_minutes]).to eq([ Service::DURATION_NOT_WHOLE_MESSAGE ])
    end

    it "is invalid when letters trail the duration" do
      service = build(:service, duration_minutes: "45min")

      service.valid?

      expect(service.errors[:duration_minutes]).to eq([ Service::DURATION_NOT_WHOLE_MESSAGE ])
    end

    it "is valid when the duration arrives as whole minutes in text" do
      service = build(:service, duration_minutes: "45")

      expect(service).to be_valid
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
    it "is invalid without a price, asking for one" do
      service = build(:service, price_cents: nil)

      service.valid?

      expect(service.errors[:price_cents]).to eq([ Service::PRICE_REQUIRED_MESSAGE ])
    end

    it "is invalid with a negative price, naming the accepted range" do
      service = build(:service, price_cents: -1)

      service.valid?

      expect(service.errors[:price_cents]).to eq([ Service::PRICE_OUT_OF_RANGE_MESSAGE ])
    end

    it "is valid with a price of zero" do
      service = build(:service, price_cents: 0)

      expect(service).to be_valid
    end

    it "is invalid one cent above the highest price" do
      service = build(:service, price_cents: Service::MAX_PRICE_CENTS + 1)

      service.valid?

      expect(service.errors[:price_cents]).to eq([ Service::PRICE_OUT_OF_RANGE_MESSAGE ])
    end

    it "is valid at the highest price" do
      service = build(:service, price_cents: Service::MAX_PRICE_CENTS)

      expect(service).to be_valid
    end

    it "names the accepted range in reais" do
      expect(Service::PRICE_OUT_OF_RANGE_MESSAGE).to eq("use um valor entre R$ 0,00 e R$ 99.999,99")
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
