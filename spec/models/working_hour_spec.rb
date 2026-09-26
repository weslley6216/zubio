require "rails_helper"

RSpec.describe WorkingHour, type: :model do
  describe "creation" do
    it "persists a valid range with the right tenant and professional" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)

      working_hour = ActsAsTenant.with_tenant(tenant) do
        WorkingHour.create!(tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      end

      expect(working_hour.tenant).to eq(tenant)
      expect(working_hour.professional).to eq(professional)
    end

    it "accepts two ranges on the same day, morning and afternoon" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)

      morning = build(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      afternoon = build(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "14:00", closes_at: "18:00")

      ActsAsTenant.with_tenant(tenant) do
        morning.save!
        afternoon.save!
      end

      expect(afternoon).to be_persisted
    end

    it "rejects an overlapping range on the same day, adding the error to opens_at" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "13:00") }
      overlapping = build(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "10:00", closes_at: "12:00")

      ActsAsTenant.with_tenant(tenant) { overlapping.valid? }

      expect(overlapping.errors[:opens_at]).to be_present
    end

    it "accepts ranges that only touch at the boundary" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00") }
      touching = build(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "12:00", closes_at: "15:00")

      valid = ActsAsTenant.with_tenant(tenant) { touching.valid? }

      expect(valid).to be true
    end

    it "accepts the same range on another day" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00") }
      another_day = build(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "09:00", closes_at: "18:00")

      valid = ActsAsTenant.with_tenant(tenant) { another_day.valid? }

      expect(valid).to be true
    end

    it "accepts the same range for another professional" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      another_professional = create(:professional, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00") }
      same_range = build(:working_hour, tenant: tenant, professional: another_professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")

      valid = ActsAsTenant.with_tenant(tenant) { same_range.valid? }

      expect(valid).to be true
    end

    it "rejects closing at or before opening" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      same_instant = build(:working_hour, tenant: tenant, professional: professional, opens_at: "09:00", closes_at: "09:00")
      before_opening = build(:working_hour, tenant: tenant, professional: professional, opens_at: "18:00", closes_at: "09:00")

      ActsAsTenant.with_tenant(tenant) do
        same_instant.valid?
        before_opening.valid?
      end

      expect(same_instant.errors[:closes_at]).to be_present
      expect(before_opening.errors[:closes_at]).to be_present
    end

    it "rejects a range off the five-minute step" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      off_step = build(:working_hour, tenant: tenant, professional: professional, opens_at: "09:03", closes_at: "18:00")

      ActsAsTenant.with_tenant(tenant) { off_step.valid? }

      expect(off_step.errors[:opens_at]).to be_present
    end

    it "rejects a range carrying seconds" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      with_seconds = build(:working_hour, tenant: tenant, professional: professional, opens_at: "09:00:30", closes_at: "18:00")

      ActsAsTenant.with_tenant(tenant) { with_seconds.valid? }

      expect(with_seconds.errors[:opens_at]).to be_present
    end

    it "accepts a range aligned to the five-minute step" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      aligned = build(:working_hour, tenant: tenant, professional: professional, opens_at: "09:05", closes_at: "18:00")

      valid = ActsAsTenant.with_tenant(tenant) { aligned.valid? }

      expect(valid).to be true
    end

    it "rejects a weekday outside 0..6" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      out_of_range = build(:working_hour, tenant: tenant, professional: professional, weekday: 7)

      ActsAsTenant.with_tenant(tenant) { out_of_range.valid? }

      expect(out_of_range.errors[:weekday]).to be_present
    end

    it "rejects a nil weekday" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      nil_weekday = build(:working_hour, tenant: tenant, professional: professional, weekday: nil)

      ActsAsTenant.with_tenant(tenant) { nil_weekday.valid? }

      expect(nil_weekday.errors[:weekday]).to be_present
    end

    it "accepts the boundary weekdays 0 and 6" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      sunday = build(:working_hour, tenant: tenant, professional: professional, weekday: 0)
      saturday = build(:working_hour, tenant: tenant, professional: professional, weekday: 6)

      valid = ActsAsTenant.with_tenant(tenant) { sunday.valid? & saturday.valid? }

      expect(valid).to be true
    end

    it "does not invalidate an overlapping range in another tenant" do
      first_tenant = create(:tenant)
      first_professional = create(:professional, tenant: first_tenant)
      ActsAsTenant.with_tenant(first_tenant) { create(:working_hour, tenant: first_tenant, professional: first_professional, weekday: 2, opens_at: "09:00", closes_at: "13:00") }
      second_tenant = create(:tenant)
      second_professional = create(:professional, tenant: second_tenant)
      overlapping_elsewhere = build(:working_hour, tenant: second_tenant, professional: second_professional, weekday: 2, opens_at: "10:00", closes_at: "12:00")

      valid = ActsAsTenant.with_tenant(second_tenant) { overlapping_elsewhere.valid? }

      expect(valid).to be true
    end
  end

  describe "scopes" do
    it "returns only the requested day through for_weekday" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      tuesday = ActsAsTenant.with_tenant(tenant) do
        create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "09:00", closes_at: "12:00")
        create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      end

      results = ActsAsTenant.with_tenant(tenant) { WorkingHour.for_weekday(2).to_a }

      expect(results).to eq([ tuesday ])
    end

    it "orders by weekday then opens_at" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      wednesday, tuesday_afternoon, tuesday_morning = ActsAsTenant.with_tenant(tenant) do
        [
          create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "09:00", closes_at: "12:00"),
          create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "14:00", closes_at: "18:00"),
          create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
        ]
      end

      results = ActsAsTenant.with_tenant(tenant) { WorkingHour.ordered.to_a }

      expect(results).to eq([ tuesday_morning, tuesday_afternoon, wednesday ])
    end
  end

  describe "tenant isolation" do
    it "does not bring another tenant's row through for_weekday or ordered" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      own = ActsAsTenant.with_tenant(tenant) { create(:working_hour, tenant: tenant, professional: professional, weekday: 2) }
      other_tenant = create(:tenant)
      other_professional = create(:professional, tenant: other_tenant)
      ActsAsTenant.with_tenant(other_tenant) { create(:working_hour, tenant: other_tenant, professional: other_professional, weekday: 2) }

      results = ActsAsTenant.with_tenant(tenant) { WorkingHour.for_weekday(2).ordered.to_a }

      expect(results).to contain_exactly(own)
    end
  end
  describe ".day_segments" do
    it "returns a single range when there is no break" do
      expect(described_class.day_segments("09:00", "18:00", nil, nil)).to eq([ [ "09:00", "18:00" ] ])
    end

    it "splits the day around the break into two ranges" do
      expect(described_class.day_segments("09:00", "18:00", "12:00", "14:00")).to eq([ [ "09:00", "12:00" ], [ "14:00", "18:00" ] ])
    end
  end
end
