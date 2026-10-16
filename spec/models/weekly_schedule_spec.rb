require "rails_helper"

RSpec.describe WeeklySchedule do
  describe ".from_professional" do
    it "reads a two-row day as an expediente with a break" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "12:00" ], [ "14:00", "18:00" ] ]) }

      schedule = ActsAsTenant.with_tenant(tenant) { described_class.from_professional(professional) }

      expect(schedule.marked?(2)).to be(true)
      expect([ schedule.opens_at(2), schedule.closes_at(2) ]).to eq([ "09:00", "18:00" ])
      expect([ schedule.break_starts_at(2), schedule.break_ends_at(2) ]).to eq([ "12:00", "14:00" ])
    end

    it "reads a single-row day as an expediente without a break and leaves the rest blank" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }

      schedule = ActsAsTenant.with_tenant(tenant) { described_class.from_professional(professional) }

      expect(schedule.break?(2)).to be(false)
      expect(schedule.marked?(3)).to be(false)
      expect(schedule.opens_at(3)).to eq("")
    end
  end

  describe "#save" do
    it "stores a day with no break as one row" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      saved = ActsAsTenant.with_tenant(tenant) do
        described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at" => "09:00", "closes_at" => "18:00" } }).save
      end

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.to_a }
      expect(saved).to be(true)
      expect(hours.map { |working_hour| [ working_hour.opens_at.strftime("%H:%M"), working_hour.closes_at.strftime("%H:%M") ] }).to eq([ [ "09:00", "18:00" ] ])
    end

    it "stores a day with a break as the two rows around it" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      ActsAsTenant.with_tenant(tenant) do
        described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at" => "09:00", "closes_at" => "18:00", "break_starts_at" => "12:00", "break_ends_at" => "13:00" } }).save
      end

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.to_a }
      expect(hours.map { |working_hour| [ working_hour.opens_at.strftime("%H:%M"), working_hour.closes_at.strftime("%H:%M") ] }).to eq([ [ "09:00", "12:00" ], [ "13:00", "18:00" ] ])
    end

    it "removes the days left unmarked" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ], 3 => [ [ "09:00", "18:00" ] ]) }

      ActsAsTenant.with_tenant(tenant) do
        described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at" => "09:00", "closes_at" => "18:00" } }).save
      end

      weekdays = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.map(&:weekday) }
      expect(weekdays).to eq([ 2 ])
    end

    it "refuses an inverted expediente with the prancheta message, flags the hours and writes nothing" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }

      schedule = described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at" => "09:00", "closes_at" => "18:00" }, "4" => { "active" => "1", "opens_at" => "18:00", "closes_at" => "09:00" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      weekdays = ActsAsTenant.with_tenant(tenant) { professional.reload.working_hours.ordered.map(&:weekday) }
      expect(saved).to be(false)
      expect(schedule.errors_for(4)).to eq([ WeeklySchedule::INVERTED_MESSAGE ])
      expect([ schedule.hours_rejected?(4), schedule.break_rejected?(4) ]).to eq([ true, false ])
      expect(weekdays).to eq([ 2 ])
    end

    it "refuses a break that spills past the expediente, flags the break and writes nothing" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      schedule = described_class.new(professional: professional, days: { "4" => { "active" => "1", "opens_at" => "09:00", "closes_at" => "18:00", "break_starts_at" => "17:30", "break_ends_at" => "18:30" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      hours = ActsAsTenant.with_tenant(tenant) { professional.working_hours.to_a }
      expect(saved).to be(false)
      expect(schedule.errors_for(4)).to eq([ "O intervalo precisa caber entre 09:00 e 18:00. Nada foi salvo." ])
      expect([ schedule.break_rejected?(4), schedule.hours_rejected?(4) ]).to eq([ true, false ])
      expect(hours).to be_empty
    end

    it "refuses a break whose end is on or before its start" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      schedule = described_class.new(professional: professional, days: { "4" => { "active" => "1", "opens_at" => "09:00", "closes_at" => "18:00", "break_starts_at" => "14:00", "break_ends_at" => "12:00" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      expect(saved).to be(false)
      expect(schedule.errors_for(4)).to eq([ WeeklySchedule::INVERTED_MESSAGE ])
      expect(schedule.break_rejected?(4)).to be(true)
    end

    it "accepts a break that fits inside the expediente" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      saved = ActsAsTenant.with_tenant(tenant) do
        described_class.new(professional: professional, days: { "4" => { "active" => "1", "opens_at" => "09:00", "closes_at" => "18:00", "break_starts_at" => "12:00", "break_ends_at" => "13:00" } }).save
      end

      expect(saved).to be(true)
    end

    it "refuses a time off the five-minute step with a legible error" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      schedule = described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at" => "09:03", "closes_at" => "18:00" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      expect(saved).to be(false)
      expect(schedule.errors_for(2)).to eq([ "use múltiplos de 5 minutos" ])
    end

    it "refuses a marked day whose closing is left blank" do
      tenant = create(:tenant)
      professional = create(:professional, :without_user, tenant: tenant)

      schedule = described_class.new(professional: professional, days: { "2" => { "active" => "1", "opens_at" => "09:00", "closes_at" => "" } })
      saved = ActsAsTenant.with_tenant(tenant) { schedule.save }

      expect(saved).to be(false)
      expect(schedule.errors_for(2)).to include("não pode ficar em branco")
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
        described_class.new(professional: professional, days: { "3" => { "active" => "1", "opens_at" => "10:00", "closes_at" => "16:00" } }).save
      end

      weekdays = ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.map(&:weekday) }
      other_weekdays = ActsAsTenant.with_tenant(other_tenant) { other_professional.working_hours.ordered.map(&:weekday) }
      expect(weekdays).to eq([ 3 ])
      expect(other_weekdays).to eq([ 2 ])
    end
  end
end
