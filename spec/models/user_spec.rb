require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is invalid without an email" do
      user = build(:user, email: nil)

      expect(user).not_to be_valid
    end

    it "is invalid without a name" do
      user = build(:user, name: nil)

      expect(user).not_to be_valid
    end

    it "is invalid with a duplicate email in the same tenant" do
      tenant = create(:tenant)
      create(:user, tenant: tenant, email: "owner@example.com")
      user = build(:user, tenant: tenant, email: "owner@example.com")

      expect(user).not_to be_valid
    end

    it "is valid with the same email in different tenants" do
      create(:user, email: "owner@example.com")
      user = build(:user, email: "owner@example.com")

      expect(user).to be_valid
    end
  end

  describe "tenant isolation" do
    it "does not include users from another tenant" do
      tenant_a = create(:tenant)
      tenant_b = create(:tenant)
      create(:user, tenant: tenant_a)

      result = ActsAsTenant.with_tenant(tenant_b) { User.all }

      expect(result).to be_empty
    end

    it "includes the user from its own tenant" do
      tenant_a = create(:tenant)
      user = create(:user, tenant: tenant_a)

      result = ActsAsTenant.with_tenant(tenant_a) { User.all }

      expect(result).to include(user)
    end
  end
end
