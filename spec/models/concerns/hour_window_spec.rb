require "rails_helper"

RSpec.describe HourWindow, type: :model do
  it "is shared by the models that carry an hour window" do
    expect(WorkingHour.include?(described_class)).to be true
    expect(ScheduleException.include?(described_class)).to be true
  end

  [
    [ :working_hour, {} ],
    [ :schedule_exception, { closed: false } ]
  ].each do |factory_name, window_state|
    context "in #{factory_name}" do
      it "rejects a window that closes at or before it opens" do
        tenant = create(:tenant)
        professional = create(:professional, tenant: tenant)
        inverted = build(factory_name, tenant: tenant, professional: professional, opens_at: "12:00", closes_at: "09:00", **window_state)

        ActsAsTenant.with_tenant(tenant) { inverted.valid? }

        expect(inverted.errors[:closes_at]).to be_present
      end

      it "rejects a window off the five-minute step" do
        tenant = create(:tenant)
        professional = create(:professional, tenant: tenant)
        off_step = build(factory_name, tenant: tenant, professional: professional, opens_at: "09:03", closes_at: "12:00", **window_state)

        ActsAsTenant.with_tenant(tenant) { off_step.valid? }

        expect(off_step.errors[:opens_at]).to be_present
      end

      it "accepts a window aligned to the five-minute step" do
        tenant = create(:tenant)
        professional = create(:professional, tenant: tenant)
        aligned = build(factory_name, tenant: tenant, professional: professional, opens_at: "09:05", closes_at: "12:00", **window_state)

        valid = ActsAsTenant.with_tenant(tenant) { aligned.valid? }

        expect(valid).to be true
      end
    end
  end
end
