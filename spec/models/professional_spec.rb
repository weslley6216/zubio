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

  describe "associations" do
    it "belongs to an optional user" do
      tenant = create(:tenant)

      ActsAsTenant.with_tenant(tenant) do
        expect(described_class.new).to belong_to(:user).optional
      end
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

  describe "user uniqueness" do
    it "is invalid when the user is already linked to another professional" do
      tenant = create(:tenant)
      user = create(:user, tenant: tenant)
      create(:professional, :without_user, tenant: tenant, user: user)
      professional = build(:professional, :without_user, tenant: tenant, user: user)

      ActsAsTenant.with_tenant(tenant) { professional.valid? }

      expect(professional.errors.details[:user_id]).to include(hash_including(error: :taken))
    end

    it "is valid when each professional has a different user" do
      tenant = create(:tenant)
      user_one = create(:user, tenant: tenant)
      user_two = create(:user, tenant: tenant)
      create(:professional, :without_user, tenant: tenant, user: user_one)
      professional = build(:professional, :without_user, tenant: tenant, user: user_two)

      is_valid = ActsAsTenant.with_tenant(tenant) { professional.valid? }

      expect(is_valid).to be true
    end
  end

  describe "#replace_weekly_hours!" do
    it "creates one range per marked weekday with no break" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      ActsAsTenant.with_tenant(tenant) do
        professional.replace_weekly_hours!(weekdays: [ 2, 3, 4, 5, 6 ], opens_at: "09:00", closes_at: "18:00")
      end

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.to_a }
      ranges = hours.map { |hour| [ hour.opens_at.strftime("%H:%M"), hour.closes_at.strftime("%H:%M") ] }
      expect(hours.size).to eq(5)
      expect(ranges.uniq).to eq([ [ "09:00", "18:00" ] ])
    end

    it "splits each marked weekday around the break, leaving no range covering it" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      ActsAsTenant.with_tenant(tenant) do
        professional.replace_weekly_hours!(weekdays: [ 2, 3, 4, 5, 6 ], opens_at: "09:00", closes_at: "18:00",
          break_starts_at: "12:00", break_ends_at: "14:00")
      end

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.to_a }
      ranges = hours.map { |hour| [ hour.opens_at.strftime("%H:%M"), hour.closes_at.strftime("%H:%M") ] }
      expect(hours.size).to eq(10)
      expect(ranges.uniq.sort).to eq([ [ "09:00", "12:00" ], [ "14:00", "18:00" ] ])
      expect(ranges).to all(satisfy { |opens, closes| !(opens < "14:00" && "12:00" < closes) })
    end

    it "replaces instead of accumulating on a second call" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { professional.replace_weekly_hours!(weekdays: [ 2, 3, 4, 5, 6 ], opens_at: "09:00", closes_at: "18:00") }

      ActsAsTenant.with_tenant(tenant) { professional.replace_weekly_hours!(weekdays: [ 1 ], opens_at: "10:00", closes_at: "16:00") }

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.to_a }
      expect(hours.size).to eq(1)
    end

    it "rolls back without an orphan range when a segment is invalid" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { professional.replace_weekly_hours!(weekdays: [ 2 ], opens_at: "09:00", closes_at: "18:00") }

      expect do
        ActsAsTenant.with_tenant(tenant) { professional.replace_weekly_hours!(weekdays: [ 3 ], opens_at: "09:00", closes_at: "09:00") }
      end.to raise_error(ActiveRecord::RecordInvalid)

      hours = ActsAsTenant.with_tenant(tenant) { professional.reload.working_hours.to_a }
      expect(hours.size).to eq(1)
    end

    it "writes only to the target professional and tenant" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      other_tenant = create(:tenant)
      other_professional = create(:professional, :without_user, tenant: other_tenant)

      ActsAsTenant.with_tenant(tenant) { professional.replace_weekly_hours!(weekdays: [ 2 ], opens_at: "09:00", closes_at: "18:00") }

      other_hours = ActsAsTenant.with_tenant(other_tenant) { other_professional.working_hours.to_a }
      expect(other_hours).to be_empty
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
