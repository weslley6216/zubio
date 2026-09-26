require "rails_helper"

RSpec.describe Onboarding::Schedule, type: :model do
  it "rejects a schedule with no weekday marked" do
    schedule = described_class.new(weekdays: [], opens_at: "09:00", closes_at: "18:00")

    schedule.valid?

    expect(schedule.errors[:weekdays]).to include(Onboarding::Schedule::NO_WEEKDAY_MESSAGE)
  end

  it "accepts at least one weekday with a well-formed range" do
    tenant = create(:tenant)
    professional = create(:professional, :without_user, tenant: tenant)

    is_valid = ActsAsTenant.with_tenant(tenant) do
      described_class.new(professional: professional, weekdays: [ 2, 3 ], opens_at: "09:00", closes_at: "18:00").valid?
    end

    expect(is_valid).to be(true)
  end

  it "flags the closing field when a marked day has no closing time" do
    tenant = create(:tenant)
    professional = create(:professional, :without_user, tenant: tenant)

    schedule = ActsAsTenant.with_tenant(tenant) do
      described_class.new(professional: professional, weekdays: [ 2 ], opens_at: "09:00", closes_at: "").tap(&:valid?)
    end

    expect(schedule.errors[:closes_at]).to include("não pode ficar em branco")
  end

  it "flags the range when the lunch break inverts the afternoon segment" do
    tenant = create(:tenant)
    professional = create(:professional, :without_user, tenant: tenant)

    schedule = ActsAsTenant.with_tenant(tenant) do
      described_class.new(professional: professional, weekdays: [ 2 ], opens_at: "09:00", closes_at: "13:00",
        break_starts_at: "12:00", break_ends_at: "18:00").tap(&:valid?)
    end

    expect(schedule.errors[:closes_at]).to be_present
  end

  it "flags the lunch end when the break ends before it starts inside the working range" do
    tenant = create(:tenant)
    professional = create(:professional, :without_user, tenant: tenant)

    schedule = ActsAsTenant.with_tenant(tenant) do
      described_class.new(professional: professional, weekdays: [ 2 ], opens_at: "09:00", closes_at: "18:00",
        break_starts_at: "14:00", break_ends_at: "12:00").tap(&:valid?)
    end

    expect(schedule.errors[:break_ends_at]).to include(Onboarding::Schedule::BREAK_INVERTED_MESSAGE)
  end

  it "accepts a lunch break that ends after it starts" do
    tenant = create(:tenant)
    professional = create(:professional, :without_user, tenant: tenant)

    is_valid = ActsAsTenant.with_tenant(tenant) do
      described_class.new(professional: professional, weekdays: [ 2 ], opens_at: "09:00", closes_at: "18:00",
        break_starts_at: "12:00", break_ends_at: "14:00").valid?
    end

    expect(is_valid).to be(true)
  end

  it "hands the raw answers to replace_weekly_hours!" do
    schedule = described_class.new(weekdays: [ 2, 3 ], opens_at: "09:00", closes_at: "18:00", break_starts_at: "12:00", break_ends_at: "14:00")

    expect(schedule.schedule_attributes).to eq(
      weekdays: [ 2, 3 ], opens_at: "09:00", closes_at: "18:00", break_starts_at: "12:00", break_ends_at: "14:00"
    )
  end

  it "marks a weekday that was answered and not one that was left out" do
    schedule = described_class.new(weekdays: [ 2, 3 ], opens_at: "09:00", closes_at: "18:00")

    expect(schedule.marked?(2)).to be(true)
    expect(schedule.marked?(4)).to be(false)
  end

  it "checks its candidates in the current tenant only, ignoring another tenant's hours" do
    tenant = create(:tenant)
    professional = create(:professional, :without_user, tenant: tenant)
    other_tenant = create(:tenant)
    other_professional = create(:professional, :without_user, tenant: other_tenant)
    ActsAsTenant.with_tenant(other_tenant) { other_professional.replace_weekly_hours!(weekdays: [ 2 ], opens_at: "09:00", closes_at: "18:00") }

    is_valid = ActsAsTenant.with_tenant(tenant) do
      described_class.new(professional: professional, weekdays: [ 2 ], opens_at: "09:00", closes_at: "18:00").valid?
    end

    expect(is_valid).to be(true)
  end
end
