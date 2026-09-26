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
        ScheduleException.create!(tenant: tenant, professional: professional, occurs_on: Date.current.next_occurring(:saturday), closed: false, opens_at: "09:00", closes_at: "12:00")
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
end
