require "rails_helper"

RSpec.describe ScheduleException, type: :model do
  describe "creation" do
    it "persists a full-day closure for the current tenant, born closed without a window" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)

      exception = ActsAsTenant.with_tenant(tenant) do
        ScheduleException.create!(tenant: tenant, professional: professional, occurs_on: Date.current.next_week(:monday))
      end

      expect(exception.tenant).to eq(tenant)
      expect(exception).to be_closed
      expect(exception.opens_at).to be_nil
      expect(exception.closes_at).to be_nil
    end

    it "requires a date" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      no_date = build(:schedule_exception, tenant: tenant, professional: professional, occurs_on: nil)

      ActsAsTenant.with_tenant(tenant) { no_date.valid? }

      expect(no_date.errors[:occurs_on]).to be_present
    end
  end

  describe "window coherence" do
    it "persists an alternate-hours exception keeping the given window" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)

      exception = ActsAsTenant.with_tenant(tenant) do
        create(:schedule_exception, :with_alternate_hours, tenant: tenant, professional: professional, occurs_on: Date.current.next_occurring(:saturday))
      end

      expect(exception).not_to be_closed
      expect(exception.opens_at.strftime("%H:%M")).to eq("09:00")
      expect(exception.closes_at.strftime("%H:%M")).to eq("12:00")
    end

    it "rejects a closed day carrying a window" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      closed_with_window = build(:schedule_exception, tenant: tenant, professional: professional, closed: true, opens_at: "09:00", closes_at: "12:00")

      ActsAsTenant.with_tenant(tenant) { closed_with_window.valid? }

      expect(closed_with_window.errors[:opens_at]).to be_present
    end

    it "rejects a closed day carrying only an opening time" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      half_window = build(:schedule_exception, tenant: tenant, professional: professional, closed: true, opens_at: "09:00", closes_at: nil)

      ActsAsTenant.with_tenant(tenant) { half_window.valid? }

      expect(half_window.errors[:opens_at]).to be_present
    end

    it "rejects an open day without a window, adding the error to opens_at" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      open_without_window = build(:schedule_exception, tenant: tenant, professional: professional, closed: false)

      ActsAsTenant.with_tenant(tenant) { open_without_window.valid? }

      expect(open_without_window.errors[:opens_at]).to be_present
    end

    it "rejects an open day missing the closing time" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      half_open = build(:schedule_exception, tenant: tenant, professional: professional, closed: false, opens_at: "09:00", closes_at: nil)

      ActsAsTenant.with_tenant(tenant) { half_open.valid? }

      expect(half_open.errors[:opens_at]).to be_present
    end
  end

  describe "reason" do
    it "normalizes reason, trimming surrounding blanks" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      exception = build(:schedule_exception, tenant: tenant, professional: professional)

      exception.reason = "  Feriado  "

      expect(exception.reason).to eq("Feriado")
    end

    it "normalizes a blank reason to nil" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      exception = build(:schedule_exception, tenant: tenant, professional: professional)

      exception.reason = "   "

      expect(exception.reason).to be_nil
    end
  end

  describe "uniqueness" do
    it "rejects a second exception on the same date for the same professional, adding the error to occurs_on" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      date = Date.current.next_week(:monday)
      ActsAsTenant.with_tenant(tenant) { create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: date) }
      duplicate = build(:schedule_exception, tenant: tenant, professional: professional, occurs_on: date)

      ActsAsTenant.with_tenant(tenant) { duplicate.valid? }

      expect(duplicate.errors[:occurs_on]).to be_present
    end

    it "accepts the same date for another professional in the same tenant" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      another_professional = create(:professional, tenant: tenant)
      date = Date.current.next_week(:monday)
      ActsAsTenant.with_tenant(tenant) { create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: date) }
      same_date = build(:schedule_exception, tenant: tenant, professional: another_professional, occurs_on: date)

      valid = ActsAsTenant.with_tenant(tenant) { same_date.valid? }

      expect(valid).to be true
    end

    it "accepts the same date in another tenant" do
      first_tenant = create(:tenant)
      first_professional = create(:professional, tenant: first_tenant)
      date = Date.current.next_week(:monday)
      ActsAsTenant.with_tenant(first_tenant) { create(:schedule_exception, tenant: first_tenant, professional: first_professional, occurs_on: date) }
      second_tenant = create(:tenant)
      second_professional = create(:professional, tenant: second_tenant)
      same_date_elsewhere = build(:schedule_exception, tenant: second_tenant, professional: second_professional, occurs_on: date)

      valid = ActsAsTenant.with_tenant(second_tenant) { same_date_elsewhere.valid? }

      expect(valid).to be true
    end
  end

  describe "scopes" do
    it "returns upcoming exceptions ordered by date and excludes past ones" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      later = nil
      sooner = nil
      ActsAsTenant.with_tenant(tenant) do
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current - 1)
        later = create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current + 14)
        sooner = create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current + 3)
      end

      results = ActsAsTenant.with_tenant(tenant) { ScheduleException.upcoming.to_a }

      expect(results).to eq([ sooner, later ])
    end

    it "includes an exception dated today in upcoming" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      today = ActsAsTenant.with_tenant(tenant) { create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current) }

      results = ActsAsTenant.with_tenant(tenant) { ScheduleException.upcoming.to_a }

      expect(results).to include(today)
    end

    it "returns only the exceptions inside the requested range through within" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      inside = nil
      ActsAsTenant.with_tenant(tenant) do
        inside = create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current + 2)
        create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current + 30)
      end

      results = ActsAsTenant.with_tenant(tenant) { ScheduleException.within(Date.current..(Date.current + 7)).to_a }

      expect(results).to eq([ inside ])
    end

    it "includes exceptions on the range boundaries through within" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      first_day = nil
      last_day = nil
      ActsAsTenant.with_tenant(tenant) do
        first_day = create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current)
        last_day = create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current + 7)
      end

      results = ActsAsTenant.with_tenant(tenant) { ScheduleException.within(Date.current..(Date.current + 7)).to_a }

      expect(results).to contain_exactly(first_day, last_day)
    end
  end

  describe "tenant isolation" do
    it "brings the current tenant's exception and not another tenant's" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      own = ActsAsTenant.with_tenant(tenant) { create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: Date.current + 5) }
      other_tenant = create(:tenant)
      other_professional = create(:professional, tenant: other_tenant)
      ActsAsTenant.with_tenant(other_tenant) { create(:schedule_exception, tenant: other_tenant, professional: other_professional, occurs_on: Date.current + 5) }

      results = ActsAsTenant.with_tenant(tenant) { ScheduleException.upcoming.to_a }

      expect(results).to contain_exactly(own)
    end
  end
end
