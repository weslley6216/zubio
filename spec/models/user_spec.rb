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

    it "is invalid without a role" do
      user = build(:user, role: nil)

      expect(user).not_to be_valid
    end

    it "rejects a role outside the enum" do
      expect { build(:user, role: "superadmin") }.to raise_error(ArgumentError)
    end
  end

  describe "authentication" do
    it "authenticates with the correct password" do
      user = create(:user, password: "s3cr3t123")

      expect(user.authenticate("s3cr3t123")).to eq(user)
    end

    it "does not authenticate with an incorrect password" do
      user = create(:user, password: "s3cr3t123")

      expect(user.authenticate("wrong")).to be false
    end
  end

  describe "owner handoff token" do
    it "resolves back to the user who minted it" do
      user = create(:user)

      expect(User.find_by_handoff_token(user.handoff_token)).to eq(user)
    end

    it "stops resolving once the password changes" do
      user = create(:user, password: "s3cr3t123")
      token = user.handoff_token

      user.update!(password: "an0th3rpass", password_confirmation: "an0th3rpass")

      expect(User.find_by_handoff_token(token)).to be_nil
    end

    it "stops resolving once it is consumed" do
      user = create(:user)
      token = user.handoff_token

      user.consume_handoff_token!

      expect(User.find_by_handoff_token(token)).to be_nil
    end

    it "stops resolving once it expires" do
      user = create(:user)
      token = travel_to(1.hour.ago) { user.handoff_token }

      expect(User.find_by_handoff_token(token)).to be_nil
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
