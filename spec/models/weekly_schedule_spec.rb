require "rails_helper"

RSpec.describe WeeklySchedule do
  describe ".from_professional" do
    it "marks the saved days with their ranges and leaves the rest blank" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "12:00" ], [ "14:00", "18:00" ] ]) }

      schedule = ActsAsTenant.with_tenant(tenant) { described_class.from_professional(professional) }

      expect(schedule.marked?(2)).to be(true)
      expect(schedule.marked?(3)).to be(false)
      expect(schedule.ranges_for(2)).to eq([ [ "09:00", "12:00" ], [ "14:00", "18:00" ] ])
    end
  end

  describe "#save" do
    it "stores a single day with one range" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      saved = ActsAsTenant.with_tenant(tenant) do
        described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at_0" => "09:00", "closes_at_0" => "18:00" } }).save
      end

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.to_a }
      expect(saved).to be(true)
      expect(hours.map { |working_hour| [ working_hour.weekday, working_hour.opens_at.strftime("%H:%M"), working_hour.closes_at.strftime("%H:%M") ] })
        .to eq([ [ 2, "09:00", "18:00" ] ])
    end

    it "stores two ranges for the same day" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      ActsAsTenant.with_tenant(tenant) do
        described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at_0" => "09:00", "closes_at_0" => "12:00", "opens_at_1" => "14:00", "closes_at_1" => "18:00" } }).save
      end

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.to_a }
      expect(hours.size).to eq(2)
    end

    it "removes the days left unmarked" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ], 3 => [ [ "09:00", "18:00" ] ]) }

      ActsAsTenant.with_tenant(tenant) do
        described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at_0" => "09:00", "closes_at_0" => "18:00" } }).save
      end

      weekdays = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.map(&:weekday) }
      expect(weekdays).to eq([ 2 ])
    end

    it "refuses an inverted range, flags the day and writes nothing" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }

      schedule = described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at_0" => "09:00", "closes_at_0" => "18:00" }, "3" => { "active" => "1", "opens_at_0" => "18:00", "closes_at_0" => "09:00" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      weekdays = ActsAsTenant.with_tenant(tenant) { professional.reload.working_hours.ordered.map(&:weekday) }
      expect(saved).to be(false)
      expect(schedule.errors_for(3)).to eq([ "o fechamento precisa ser depois da abertura" ])
      expect(weekdays).to eq([ 2 ])
    end

    it "refuses a time off the five-minute step with a legible error" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      schedule = described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at_0" => "09:03", "closes_at_0" => "18:00" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      expect(saved).to be(false)
      expect(schedule.errors_for(2)).to eq([ "use múltiplos de 5 minutos" ])
    end

    it "refuses overlapping ranges on the same day with a legible error and writes nothing" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      schedule = described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at_0" => "09:00", "closes_at_0" => "12:00", "opens_at_1" => "11:00", "closes_at_1" => "15:00" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.to_a }
      expect(saved).to be(false)
      expect(schedule.errors_for(2)).to include(WeeklySchedule::OVERLAP_MESSAGE)
      expect(hours).to be_empty
    end

    it "refuses a marked day with no range at all" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      schedule = described_class.new(professional: professional, days: { "2" => { "active" => "1" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      expect(saved).to be(false)
      expect(schedule.errors_for(2)).to include(WeeklySchedule::NO_RANGE_MESSAGE)
    end

    it "refuses a range missing its closing time" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      schedule = described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at_0" => "09:00" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      expect(saved).to be(false)
      expect(schedule.errors_for(2)).to include(WeeklySchedule::INCOMPLETE_RANGE_MESSAGE)
    end

    it "keeps a lone second range as the day's only range" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      ActsAsTenant.with_tenant(tenant) do
        described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at_1" => "14:00", "closes_at_1" => "18:00" } }).save
      end

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.to_a }
      expect(hours.map { |working_hour| [ working_hour.opens_at.strftime("%H:%M"), working_hour.closes_at.strftime("%H:%M") ] }).to eq([ [ "14:00", "18:00" ] ])
    end
  end

  describe "tenant isolation" do
    it "writes only inside the current tenant, leaving another tenant's professional untouched" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      other_tenant = create(:tenant)
      other_professional = create(:professional, :without_user, tenant: other_tenant)
      ActsAsTenant.with_tenant(other_tenant) { other_professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }

      ActsAsTenant.with_tenant(tenant) do
        described_class.new(professional: professional, days: { "3" => { "active" => "1", "opens_at_0" => "10:00", "closes_at_0" => "16:00" } }).save
      end

      weekdays = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.map(&:weekday) }
      other_weekdays = ActsAsTenant.with_tenant(other_tenant) { other_professional.working_hours.ordered.map(&:weekday) }
      expect(weekdays).to eq([ 3 ])
      expect(other_weekdays).to eq([ 2 ])
    end
  end
end
