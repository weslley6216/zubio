require "rails_helper"

RSpec.describe Client, type: :model do
  describe "validations" do
    it "persists a valid client in the current tenant with a digits-only phone" do
      tenant = create(:tenant)
      client = build(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "(11) 98877-6655")

      ActsAsTenant.with_tenant(tenant) { client.save }

      expect(client).to be_persisted
      expect(client.tenant).to eq(tenant)
      expect(client.phone).to eq("11988776655")
    end

    it "is invalid with a punctuation variant of an existing number in the same tenant" do
      tenant = create(:tenant)
      create(:client, tenant: tenant, phone: "11988776655")
      duplicate = build(:client, tenant: tenant, phone: "(11) 98877-6655")

      duplicate.valid?

      expect(duplicate.errors[:phone]).to be_present
    end

    it "normalizes a country-code number to the same form and collides with the plain one" do
      tenant = create(:tenant)
      create(:client, tenant: tenant, phone: "+55 (11) 98877-6655")
      plain = build(:client, tenant: tenant, phone: "11988776655")

      plain.valid?

      expect(plain.errors[:phone]).to be_present
    end

    it "preserves a DDD-55 number instead of stripping it as a country code" do
      tenant = create(:tenant)
      client = build(:client, tenant: tenant, phone: "55988776655")

      ActsAsTenant.with_tenant(tenant) { client.save }

      expect(client).to be_persisted
      expect(client.phone).to eq("55988776655")
    end

    it "is valid with the same phone in a different tenant" do
      create(:client, phone: "11988776655")
      other = build(:client, phone: "11988776655")

      expect(other).to be_valid
    end

    it "is invalid with a phone too short to be a phone" do
      client = build(:client, phone: "1198877")

      client.valid?

      expect(client.errors[:phone]).to be_present
    end

    it "accepts ten and eleven digit phones" do
      ten = build(:client, phone: "1188776655")
      eleven = build(:client, phone: "11988776655")

      expect(ten).to be_valid
      expect(eleven).to be_valid
    end

    it "is invalid without a name" do
      client = build(:client, name: nil)

      client.valid?

      expect(client.errors[:name]).to be_present
    end
  end

  describe ".register" do
    it "register reuses the client by phone and updates the name" do
      tenant = create(:tenant)
      existing = create(:client, tenant: tenant, name: "Ana Ribeiro", phone: "11988776655")

      result = ActsAsTenant.with_tenant(tenant) { Client.register(name: "Ana Paula Ribeiro", phone: "(11) 98877-6655") }

      expect(result).to eq(existing)
      expect(result.reload.name).to eq("Ana Paula Ribeiro")
      expect(ActsAsTenant.with_tenant(tenant) { Client.count }).to eq(1)
    end

    it "register in one tenant does not reuse another tenant's client with the same phone" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      ze = create(:tenant, name: "Barbearia do Zé")
      create(:client, tenant: aurora, name: "Ana Aurora", phone: "11988776655")

      registered = ActsAsTenant.with_tenant(ze) { Client.register(name: "Ana Zé", phone: "11988776655") }

      expect(registered).to be_persisted
      expect(registered.tenant).to eq(ze)
      expect(registered.name).to eq("Ana Zé")
    end
  end

  describe "tenant isolation" do
    it "a scoped query brings the tenant's own client and not another's" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      ze = create(:tenant, name: "Barbearia do Zé")
      create(:client, tenant: aurora, name: "Ana Aurora", phone: "11988776655")
      create(:client, tenant: ze, name: "Bia Zé", phone: "21977665544")

      names = ActsAsTenant.with_tenant(aurora) { Client.pluck(:name) }

      expect(names).to include("Ana Aurora")
      expect(names).not_to include("Bia Zé")
    end
  end
end
