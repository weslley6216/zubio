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

    it "names a duplicate email in Portuguese, not the default English" do
      tenant = create(:tenant)
      create(:user, tenant: tenant, email: "owner@example.com")
      user = build(:user, tenant: tenant, email: "owner@example.com")

      user.valid?

      expect(user.errors[:email]).to include("já está em uso")
      expect(user.errors[:email]).not_to include("has already been taken")
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

    it "rejects a password shorter than the minimum length" do
      user = build(:user, password: "1234567")

      user.valid?

      expect(user.errors[:password]).to include("é muito curto (mínimo: 8 caracteres)")
    end

    it "accepts a password of the minimum length" do
      user = build(:user, password: "12345678")

      expect(user).to be_valid
    end

    it "stays valid when the name changes without a new password" do
      user = create(:user)

      ActsAsTenant.with_tenant(user.tenant) do
        user.reload
        user.name = "Renamed Owner"

        expect(user).to be_valid
      end
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

      ActsAsTenant.with_tenant(user.tenant) do
        expect(User.find_by_handoff_token(user.handoff_token)).to eq(user)
      end
    end

    it "stops resolving once the password changes" do
      user = create(:user, password: "s3cr3t123")
      token = user.handoff_token

      ActsAsTenant.with_tenant(user.tenant) do
        user.update!(password: "an0th3rpass", password_confirmation: "an0th3rpass")

        expect(User.find_by_handoff_token(token)).to be_nil
      end
    end

    it "stops resolving once it is consumed" do
      user = create(:user)
      token = user.handoff_token

      ActsAsTenant.with_tenant(user.tenant) do
        user.consume_handoff_token!

        expect(User.find_by_handoff_token(token)).to be_nil
      end
    end

    it "stops resolving once it expires" do
      user = create(:user)
      token = travel_to(1.hour.ago) { user.handoff_token }

      ActsAsTenant.with_tenant(user.tenant) do
        expect(User.find_by_handoff_token(token)).to be_nil
      end
    end
  end

  describe "professional association" do
    it "reaches the professional created for the owner" do
      tenant = create(:tenant)
      user = create(:user, tenant: tenant)
      professional = create(:professional, :without_user, tenant: tenant, user: user)

      result = ActsAsTenant.with_tenant(tenant) { user.reload.professional }

      expect(result).to eq(professional)
    end

    it "has no professional when none is linked" do
      tenant = create(:tenant)
      user = create(:user, tenant: tenant)

      result = ActsAsTenant.with_tenant(tenant) { user.reload.professional }

      expect(result).to be_nil
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

  describe ".login_targets_for" do
    it "returns the owners of active tenants whose email matches, each with its tenant loaded" do
      first_tenant = create(:tenant, subdomain: "barbearia-do-ze")
      second_tenant = create(:tenant, subdomain: "estudio-aurora")
      create(:user, tenant: first_tenant, email: "ze@example.com", role: "owner")
      create(:user, tenant: second_tenant, email: "ze@example.com", role: "owner")

      targets = User.login_targets_for("ze@example.com")

      expect(targets.map { |owner| owner.tenant.subdomain }).to contain_exactly("barbearia-do-ze", "estudio-aurora")
    end

    it "returns only the queried address, not an owner of a different email" do
      create(:user, email: "ze@example.com", role: "owner")
      other = create(:user, email: "ana@example.com", role: "owner")

      targets = User.login_targets_for("ze@example.com")

      expect(targets).not_to include(other)
    end

    it "excludes a user who is not an owner even with the same email" do
      tenant = create(:tenant)
      create(:user, tenant: tenant, email: "ze@example.com", role: "professional")

      expect(User.login_targets_for("ze@example.com")).to be_empty
    end

    it "excludes an owner whose tenant is suspended" do
      suspended = create(:tenant, subdomain: "fechada", status: "suspended")
      create(:user, tenant: suspended, email: "ze@example.com", role: "owner")

      expect(User.login_targets_for("ze@example.com")).to be_empty
    end

    it "matches the email ignoring case, since the column is citext" do
      create(:user, email: "ze@example.com", role: "owner")

      expect(User.login_targets_for("ZE@example.com")).not_to be_empty
    end
  end
end
