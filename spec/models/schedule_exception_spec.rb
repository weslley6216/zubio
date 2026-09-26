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
end
