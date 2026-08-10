require "rails_helper"

RSpec.describe Professional, type: :model do
  describe "validations" do
    it "is invalid without a display_name" do
      professional = build(:professional, display_name: nil)

      expect(professional).not_to be_valid
    end

    it "is valid without an associated user" do
      professional = build(:professional, :without_user)

      expect(professional).to be_valid
    end
  end

  describe "user association" do
    it "does not allow a user from another tenant" do
      tenant_a = create(:tenant)
      tenant_b = create(:tenant)
      user_from_tenant_b = create(:user, tenant: tenant_b)
      professional = build(:professional, :without_user, tenant: tenant_a, user: user_from_tenant_b)

      is_valid = ActsAsTenant.with_tenant(tenant_a) { professional.valid? }

      expect(is_valid).to be false
    end

    it "allows a user from the same tenant" do
      tenant = create(:tenant)
      user = create(:user, tenant: tenant)
      professional = build(:professional, :without_user, tenant: tenant, user: user)

      is_valid = ActsAsTenant.with_tenant(tenant) { professional.valid? }

      expect(is_valid).to be true
    end
  end

  describe "tenant isolation" do
    it "does not include professionals from another tenant" do
      tenant_a = create(:tenant)
      tenant_b = create(:tenant)
      create(:professional, :without_user, tenant: tenant_a)

      result = ActsAsTenant.with_tenant(tenant_b) { Professional.all }

      expect(result).to be_empty
    end

    it "includes the professional from its own tenant" do
      tenant_a = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant_a)

      result = ActsAsTenant.with_tenant(tenant_a) { Professional.all }

      expect(result).to include(professional)
    end
  end
end
