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
end
