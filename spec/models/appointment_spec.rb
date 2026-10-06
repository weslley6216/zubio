require "rails_helper"

RSpec.describe Appointment, type: :model do
  describe "creation" do
    it "persists a valid appointment in the current tenant, born confirmed, ending 45 minutes later" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      starts_at = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)

      appointment = ActsAsTenant.with_tenant(tenant) do
        Appointment.create!(professional: professional, service: service, starts_at: starts_at)
      end

      expect(appointment.tenant).to eq(tenant)
      expect(appointment).to be_confirmed
      expect(appointment.ends_at).to eq(starts_at + 45.minutes)
    end

    it "derives the end from the service duration when none is given" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 30)
      starts_at = Time.current.next_week(:tuesday).change(hour: 14, min: 0, sec: 0)

      appointment = ActsAsTenant.with_tenant(tenant) do
        Appointment.create!(professional: professional, service: service, starts_at: starts_at)
      end

      expect(appointment.ends_at).to eq(starts_at + 30.minutes)
    end

    it "keeps a booked appointment's end when the service duration changes" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      starts_at = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      appointment = ActsAsTenant.with_tenant(tenant) do
        Appointment.create!(professional: professional, service: service, starts_at: starts_at)
      end

      ActsAsTenant.with_tenant(tenant) { service.update!(duration_minutes: 60) }

      expect(appointment.reload.ends_at).to eq(starts_at + 45.minutes)
    end

    it "is invalid without a service and does not raise while deriving the end" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      starts_at = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      appointment = ActsAsTenant.with_tenant(tenant) { Appointment.new(professional: professional, starts_at: starts_at) }

      ActsAsTenant.with_tenant(tenant) { appointment.valid? }

      expect(appointment.errors[:service]).to be_present
    end
  end

  describe "no-overlap constraint" do
    it "rejects a second overlapping appointment for the same professional and keeps the first" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      first = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, starts_at: nine) }
      overlapping = ActsAsTenant.with_tenant(tenant) { Appointment.new(professional: professional, service: service, starts_at: nine + 30.minutes) }

      expect { ActsAsTenant.with_tenant(tenant) { overlapping.save! } }.to raise_error(ActiveRecord::StatementInvalid)

      expect(first.reload).to be_confirmed
    end

    it "accepts back-to-back appointments for the same professional" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, starts_at: nine) }

      back_to_back = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, starts_at: nine + 45.minutes) }

      expect(back_to_back).to be_persisted
    end

    it "accepts an appointment overlapping a cancelled one" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, starts_at: nine) }

      replacement = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, starts_at: nine) }

      expect(replacement).to be_persisted
    end

    it "accepts the same time for a different professional" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      another_professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, starts_at: nine) }

      twin = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: another_professional, service: service, starts_at: nine) }

      expect(twin).to be_persisted
    end

    it "rejects an appointment whose end is on or before its start" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      inverted = ActsAsTenant.with_tenant(tenant) { Appointment.new(professional: professional, service: service, starts_at: nine, ends_at: nine) }

      expect { ActsAsTenant.with_tenant(tenant) { inverted.save! } }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "scopes" do
    it "occupying returns the confirmed appointment and excludes the cancelled one" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      confirmed = nil
      ActsAsTenant.with_tenant(tenant) do
        confirmed = Appointment.create!(professional: professional, service: service, starts_at: nine)
        create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, starts_at: nine + 2.hours)
      end

      results = ActsAsTenant.with_tenant(tenant) { Appointment.occupying.to_a }

      expect(results).to contain_exactly(confirmed)
    end

    it "within returns the appointments inside the range and excludes those outside" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      inside = nil
      ActsAsTenant.with_tenant(tenant) do
        inside = Appointment.create!(professional: professional, service: service, starts_at: nine)
        Appointment.create!(professional: professional, service: service, starts_at: nine + 30.days)
      end

      results = ActsAsTenant.with_tenant(tenant) { Appointment.within(nine.beginning_of_day..(nine + 7.days)).to_a }

      expect(results).to contain_exactly(inside)
    end

    it "for_professional returns the given professional's appointments and excludes another's" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      another_professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      mine = nil
      ActsAsTenant.with_tenant(tenant) do
        mine = Appointment.create!(professional: professional, service: service, starts_at: nine)
        Appointment.create!(professional: another_professional, service: service, starts_at: nine)
      end

      results = ActsAsTenant.with_tenant(tenant) { Appointment.for_professional(professional).to_a }

      expect(results).to contain_exactly(mine)
    end
  end

  describe "tenant isolation" do
    it "brings the current tenant's appointment and not another tenant's" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      own = ActsAsTenant.with_tenant(aurora) { Appointment.create!(professional: aurora_professional, service: aurora_service, starts_at: nine) }
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze, duration_minutes: 45)
      ActsAsTenant.with_tenant(ze) { Appointment.create!(professional: ze_professional, service: ze_service, starts_at: nine) }

      results = ActsAsTenant.with_tenant(aurora) { Appointment.occupying.to_a }

      expect(results).to contain_exactly(own)
    end
  end
end
