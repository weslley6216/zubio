require "rails_helper"

RSpec.describe Tenant, type: :model do
  describe "subdomain" do
    it "is invalid without a subdomain" do
      tenant = build(:tenant, subdomain: nil)

      expect(tenant).not_to be_valid
    end

    it "is invalid with a reserved subdomain" do
      tenant = build(:tenant, subdomain: "admin")

      expect(tenant).not_to be_valid
    end

    it "is invalid with an uppercase subdomain" do
      tenant = build(:tenant, subdomain: "Barbershop")

      expect(tenant).not_to be_valid
    end

    it "is invalid with an underscore" do
      tenant = build(:tenant, subdomain: "joes_barbershop")

      expect(tenant).not_to be_valid
    end

    it "is invalid with a leading hyphen" do
      tenant = build(:tenant, subdomain: "-barbershop")

      expect(tenant).not_to be_valid
    end

    it "is invalid with fewer than 3 characters" do
      tenant = build(:tenant, subdomain: "ab")

      expect(tenant).not_to be_valid
    end

    it "is invalid with a duplicate subdomain" do
      create(:tenant, subdomain: "joes-barbershop")
      tenant = build(:tenant, subdomain: "joes-barbershop")

      expect(tenant).not_to be_valid
    end

    it "is valid with lowercase letters and a hyphen in the middle" do
      tenant = build(:tenant, subdomain: "joes-barbershop")

      expect(tenant).to be_valid
    end
  end

  describe "name" do
    it "is invalid without a name" do
      tenant = build(:tenant, name: nil)

      expect(tenant).not_to be_valid
    end
  end

  describe "status" do
    it "is active by default" do
      tenant = create(:tenant)

      expect(tenant).to be_active
    end
  end
end
