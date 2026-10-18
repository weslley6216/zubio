require "rails_helper"

RSpec.describe Appointment, type: :model do
  describe "creation" do
    it "persists a valid appointment in the current tenant, born confirmed, ending 45 minutes later" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      starts_at = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)

      appointment = ActsAsTenant.with_tenant(tenant) do
        Appointment.create!(professional: professional, service: service, client: client, starts_at: starts_at)
      end

      expect(appointment.tenant).to eq(tenant)
      expect(appointment).to be_confirmed
      expect(appointment.ends_at).to eq(starts_at + 45.minutes)
    end

    it "derives the end from the service duration when none is given" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 30)
      client = create(:client, tenant: tenant)
      starts_at = Time.current.next_week(:tuesday).change(hour: 14, min: 0, sec: 0)

      appointment = ActsAsTenant.with_tenant(tenant) do
        Appointment.create!(professional: professional, service: service, client: client, starts_at: starts_at)
      end

      expect(appointment.ends_at).to eq(starts_at + 30.minutes)
    end

    it "keeps a booked appointment's end when the service duration changes" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      starts_at = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      appointment = ActsAsTenant.with_tenant(tenant) do
        Appointment.create!(professional: professional, service: service, client: client, starts_at: starts_at)
      end

      ActsAsTenant.with_tenant(tenant) { service.update!(duration_minutes: 60) }

      expect(appointment.reload.ends_at).to eq(starts_at + 45.minutes)
    end

    it "is invalid without a service and does not raise while deriving the end" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      client = create(:client, tenant: tenant)
      starts_at = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      appointment = ActsAsTenant.with_tenant(tenant) { Appointment.new(professional: professional, client: client, starts_at: starts_at) }

      ActsAsTenant.with_tenant(tenant) { appointment.valid? }

      expect(appointment.errors[:service]).to be_present
    end
  end

  describe "cancel token" do
    it "is generated on creation" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      starts_at = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)

      appointment = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: starts_at) }

      expect(appointment.cancel_token).to be_present
    end

    it "gives two appointments different tokens" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      first = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: nine) }

      second = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: nine + 45.minutes) }

      expect(first.cancel_token).not_to eq(second.cancel_token)
    end
  end

  describe "no-overlap constraint" do
    it "rejects a second overlapping appointment for the same professional and keeps the first" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      first = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: nine) }
      overlapping = ActsAsTenant.with_tenant(tenant) { Appointment.new(professional: professional, service: service, client: client, starts_at: nine + 30.minutes) }

      expect { ActsAsTenant.with_tenant(tenant) { overlapping.save! } }.to raise_error(ActiveRecord::StatementInvalid)

      expect(first.reload).to be_confirmed
    end

    it "accepts back-to-back appointments for the same professional" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: nine) }

      back_to_back = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: nine + 45.minutes) }

      expect(back_to_back).to be_persisted
    end

    it "accepts an appointment overlapping a cancelled one" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, starts_at: nine) }

      replacement = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: nine) }

      expect(replacement).to be_persisted
    end

    it "rejects an appointment overlapping a no-show" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      ActsAsTenant.with_tenant(tenant) { create(:appointment, :no_show, tenant: tenant, professional: professional, service: service, starts_at: nine) }
      overlapping = ActsAsTenant.with_tenant(tenant) { Appointment.new(professional: professional, service: service, client: client, starts_at: nine + 30.minutes) }

      expect { ActsAsTenant.with_tenant(tenant) { overlapping.save! } }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "accepts the same time for a different professional" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      another_professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: nine) }

      twin = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: another_professional, service: service, client: client, starts_at: nine) }

      expect(twin).to be_persisted
    end

    it "rejects an appointment whose end is on or before its start" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      inverted = ActsAsTenant.with_tenant(tenant) { Appointment.new(professional: professional, service: service, client: client, starts_at: nine, ends_at: nine) }

      expect { ActsAsTenant.with_tenant(tenant) { inverted.save! } }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "scopes" do
    it "occupying returns the confirmed appointment and excludes the cancelled one" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      confirmed = nil
      ActsAsTenant.with_tenant(tenant) do
        confirmed = Appointment.create!(professional: professional, service: service, client: client, starts_at: nine)
        create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, starts_at: nine + 2.hours)
      end

      results = ActsAsTenant.with_tenant(tenant) { Appointment.occupying.to_a }

      expect(results).to contain_exactly(confirmed)
    end

    it "occupying keeps the completed and the no-show appointments" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      confirmed = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: nine)
      completed = create(:appointment, :completed, tenant: tenant, professional: professional, service: service, starts_at: nine + 2.hours)
      no_show = create(:appointment, :no_show, tenant: tenant, professional: professional, service: service, starts_at: nine + 4.hours)
      create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, starts_at: nine + 6.hours)

      results = ActsAsTenant.with_tenant(tenant) { Appointment.occupying.to_a }

      expect(results).to contain_exactly(confirmed, completed, no_show)
    end

    it "within returns the appointments inside the range and excludes those outside" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      inside = nil
      ActsAsTenant.with_tenant(tenant) do
        inside = Appointment.create!(professional: professional, service: service, client: client, starts_at: nine)
        Appointment.create!(professional: professional, service: service, client: client, starts_at: nine + 30.days)
      end

      results = ActsAsTenant.with_tenant(tenant) { Appointment.within(nine.beginning_of_day..(nine + 7.days)).to_a }

      expect(results).to contain_exactly(inside)
    end

    it "for_professional returns the given professional's appointments and excludes another's" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      another_professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      mine = nil
      ActsAsTenant.with_tenant(tenant) do
        mine = Appointment.create!(professional: professional, service: service, client: client, starts_at: nine)
        Appointment.create!(professional: another_professional, service: service, client: client, starts_at: nine)
      end

      results = ActsAsTenant.with_tenant(tenant) { Appointment.for_professional(professional).to_a }

      expect(results).to contain_exactly(mine)
    end

    it "for_day brings the day's appointments in time order" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      day = Time.current.next_week(:tuesday).to_date
      fourteen = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: day.in_time_zone.change(hour: 14)) }
      nine = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: day.in_time_zone.change(hour: 9)) }
      ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: (day + 1.day).in_time_zone.change(hour: 9)) }

      results = ActsAsTenant.with_tenant(tenant) { Appointment.for_day(day).to_a }

      expect(results).to eq([ nine, fourteen ])
    end

    it "for_day includes the cancelled appointment" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      day = Time.current.next_week(:tuesday).to_date
      confirmed = ActsAsTenant.with_tenant(tenant) { Appointment.create!(professional: professional, service: service, client: client, starts_at: day.in_time_zone.change(hour: 9)) }
      cancelled = ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, starts_at: day.in_time_zone.change(hour: 14)) }

      results = ActsAsTenant.with_tenant(tenant) { Appointment.for_day(day).to_a }

      expect(results).to contain_exactly(confirmed, cancelled)
    end
  end

  describe "tenant isolation" do
    it "brings the current tenant's appointment and not another tenant's" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      aurora_client = create(:client, tenant: aurora)
      nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
      own = ActsAsTenant.with_tenant(aurora) { Appointment.create!(professional: aurora_professional, service: aurora_service, client: aurora_client, starts_at: nine) }
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze, duration_minutes: 45)
      ze_client = create(:client, tenant: ze)
      ActsAsTenant.with_tenant(ze) { Appointment.create!(professional: ze_professional, service: ze_service, client: ze_client, starts_at: nine) }

      results = ActsAsTenant.with_tenant(aurora) { Appointment.occupying.to_a }

      expect(results).to contain_exactly(own)
    end

    it "for_day brings the own tenant's appointment and not another tenant's" do
      day = Time.current.next_week(:tuesday).to_date
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze, duration_minutes: 45)
      ze_client = create(:client, tenant: ze)
      ActsAsTenant.with_tenant(ze) { Appointment.create!(professional: ze_professional, service: ze_service, client: ze_client, starts_at: day.in_time_zone.change(hour: 9)) }
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      aurora_client = create(:client, tenant: aurora)
      own = ActsAsTenant.with_tenant(aurora) { Appointment.create!(professional: aurora_professional, service: aurora_service, client: aurora_client, starts_at: day.in_time_zone.change(hour: 9)) }

      results = ActsAsTenant.with_tenant(aurora) { Appointment.for_day(day).to_a }

      expect(results).to contain_exactly(own)
    end
  end

  describe ".book" do
    it "creates a confirmed appointment for the chosen service, professional and time and returns success" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      result = ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "Ana Paula Ribeiro", client_phone: "(11) 98877-1234") }

      expect(result.success?).to be(true)
      expect([ result.value.service, result.value.professional, result.value.starts_at, result.value.confirmed? ]).to eq([ service, professional, nine, true ])
      expect(result.value.client.phone).to eq("11988771234")
    end

    it "registers the client in the tenant" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "Ana Paula Ribeiro", client_phone: "11988771234") }

      expect(ActsAsTenant.with_tenant(tenant) { Client.where(phone: "11988771234").count }).to eq(1)
    end

    it "reuses an existing client with the same phone instead of creating a second" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      existing = create(:client, tenant: tenant, name: "Ana", phone: "11988771234")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      result = ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "Ana Paula Ribeiro", client_phone: "11988771234") }

      expect(ActsAsTenant.with_tenant(tenant) { Client.count }).to eq(1)
      expect(result.value.client).to eq(existing)
    end

    it "fails with :off_grid for a time outside the working hours and creates nothing" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      dawn = Date.new(2026, 9, 8).in_time_zone.change(hour: 3)

      result = ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: dawn, client_name: "Ana", client_phone: "11988771234") }

      expect(result.reason).to eq(:off_grid)
      expect(ActsAsTenant.with_tenant(tenant) { [ Appointment.count, Client.count ] }).to eq([ 0, 0 ])
    end

    it "fails with :off_grid for a time in the past" do
      travel_to Time.zone.local(2026, 9, 8, 15, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      result = ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "Ana", client_phone: "11988771234") }

      expect(result.reason).to eq(:off_grid)
    end

    it "fails with :off_grid for a nil time" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)

      result = ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nil, client_name: "Ana", client_phone: "11988771234") }

      expect(result.reason).to eq(:off_grid)
    end

    it "fails with :invalid_client carrying the record when the name is blank, creating no appointment" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      result = ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "", client_phone: "11988771234") }

      expect(result.reason).to eq(:invalid_client)
      expect(result.record.errors[:name]).to be_present
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(0)
    end

    it "fails with :invalid_client for a phone that is not a phone" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      result = ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "Ana", client_phone: "1198877") }

      expect(result.reason).to eq(:invalid_client)
      expect(result.record.errors[:phone]).to be_present
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(0)
    end

    it "fails with :invalid_client for a blank name even when the phone belongs to an existing client" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      create(:client, tenant: tenant, name: "Ana", phone: "11988771234")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      result = ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "", client_phone: "11988771234") }

      expect(result.reason).to eq(:invalid_client)
      expect(result.record.errors[:name]).to be_present
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.count }).to eq(0)
    end

    it "fails with :taken when the slot was booked first, creating no second appointment" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: nine)

      result = ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "Ana", client_phone: "11988771234") }

      expect(result.reason).to eq(:taken)
      expect(ActsAsTenant.with_tenant(tenant) { Appointment.occupying.count }).to eq(1)
    end

    it "rolls back the new client when the slot was taken, leaving no orphan" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: nine)

      ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "Ana", client_phone: "11999990000") }

      expect(ActsAsTenant.with_tenant(tenant) { Client.where(phone: "11999990000").count }).to eq(0)
    end

    it "does not swallow another database error as :taken" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)
      other_error = ActiveRecord::StatementInvalid.new("boom")
      allow(other_error).to receive(:cause).and_return(PG::UndefinedColumn.new)
      allow(Appointment).to receive(:create!).and_raise(other_error)

      expect { ActsAsTenant.with_tenant(tenant) { described_class.book(professional: professional, service: service, starts_at: nine, client_name: "Ana", client_phone: "11988771234") } }.to raise_error(ActiveRecord::StatementInvalid)
      expect(ActsAsTenant.with_tenant(tenant) { Client.where(phone: "11988771234").count }).to eq(0)
    end

    it "books inside the request tenant and nothing in another" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      create(:working_hour, tenant: aurora, professional: aurora_professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      ze = create(:tenant, name: "Barbearia do Zé")
      nine = Date.new(2026, 9, 8).in_time_zone.change(hour: 9)

      ActsAsTenant.with_tenant(aurora) { described_class.book(professional: aurora_professional, service: aurora_service, starts_at: nine, client_name: "Ana", client_phone: "11988771234") }

      expect(ActsAsTenant.with_tenant(aurora) { Appointment.count }).to eq(1)
      expect(ActsAsTenant.with_tenant(ze) { [ Appointment.count, Client.count ] }).to eq([ 0, 0 ])
    end
  end

  describe "cancellation" do
    it "past? is true for a start before now and false for a future one" do
      past = create(:appointment, :past)
      future = create(:appointment)

      expect(past.past?).to be(true)
      expect(future.past?).to be(false)
    end

    it "cancellable? is true for a future confirmed appointment" do
      appointment = create(:appointment)

      expect(appointment.cancellable?).to be(true)
    end

    it "cancellable? is false once the start has passed" do
      appointment = create(:appointment, :past)

      expect(appointment.cancellable?).to be(false)
    end

    it "cancellable? is false for an already cancelled appointment" do
      appointment = create(:appointment, :cancelled)

      expect(appointment.cancellable?).to be(false)
    end

    it "cancel! moves a cancellable appointment to cancelled" do
      appointment = create(:appointment)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.cancel! }

      expect(appointment.reload).to be_cancelled
    end

    it "cancel! leaves a past appointment confirmed" do
      appointment = create(:appointment, :past)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.cancel! }

      expect(appointment.reload).to be_confirmed
    end

    it "cancel! leaves an already cancelled appointment cancelled" do
      appointment = create(:appointment, :cancelled)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.cancel! }

      expect(appointment.reload).to be_cancelled
    end
  end

  describe "settlement" do
    it "accepts the four statuses" do
      expect(Appointment.statuses.keys).to eq(%w[confirmed cancelled completed no_show])
    end

    it "settleable? is true for a past confirmed appointment" do
      appointment = create(:appointment, :past)

      expect(appointment.settleable?).to be(true)
    end

    it "settleable? is true once the start has just passed" do
      appointment = create(:appointment, starts_at: 1.minute.ago)

      expect(appointment.settleable?).to be(true)
    end

    it "settleable? is false for a future appointment" do
      appointment = create(:appointment)

      expect(appointment.settleable?).to be(false)
    end

    it "settleable? is false for a cancelled appointment" do
      appointment = create(:appointment, :past, :cancelled)

      expect(appointment.settleable?).to be(false)
    end

    it "settleable? stays true for a completed or no-show appointment" do
      completed = create(:appointment, :past, :completed)
      no_show = create(:appointment, :past, :no_show)

      expect([ completed, no_show ].map(&:settleable?)).to eq([ true, true ])
    end

    it "settle! moves a past confirmed appointment to completed" do
      appointment = create(:appointment, :past)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.settle!(:completed) }

      expect(appointment.reload).to be_completed
    end

    it "settle! moves a past confirmed appointment to no_show" do
      appointment = create(:appointment, :past)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.settle!(:no_show) }

      expect(appointment.reload).to be_no_show
    end

    it "settle! corrects a no-show to completed" do
      appointment = create(:appointment, :past, :no_show)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.settle!(:completed) }

      expect(appointment.reload).to be_completed
    end

    it "settle! keeps a completed appointment completed when repeated" do
      appointment = create(:appointment, :past, :completed)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.settle!(:completed) }

      expect(appointment.reload).to be_completed
    end

    it "settle! leaves a future appointment confirmed" do
      appointment = create(:appointment)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.settle!(:completed) }

      expect(appointment.reload).to be_confirmed
    end

    it "settle! leaves a cancelled appointment cancelled" do
      appointment = create(:appointment, :past, :cancelled)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.settle!(:no_show) }

      expect(appointment.reload).to be_cancelled
    end

    it "settle! ignores an outcome outside completion and no-show" do
      appointment = create(:appointment, :past)

      ActsAsTenant.with_tenant(appointment.tenant) { appointment.settle!(:cancelled) }

      expect(appointment.reload).to be_confirmed
    end
  end

  describe ".booking_window" do
    it "spans fourteen days from today" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)

      booking_window = Appointment.booking_window

      expect([ booking_window.first, booking_window.last, booking_window.count ]).to eq([ Date.current, Date.current + 13, 14 ])
    end
  end

  describe "#visit_number" do
    it "counts the client's earlier non-cancelled appointments" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      current = ActsAsTenant.with_tenant(tenant) do
        current = create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 25, 9, 45))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 11, 9, 45))
        current
      end

      visit_number = ActsAsTenant.with_tenant(tenant) { current.visit_number }

      expect(visit_number).to eq(3)
    end

    it "skips the client's cancelled appointments" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      current = ActsAsTenant.with_tenant(tenant) do
        current = create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 25, 9, 45))
        create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 11, 9, 45))
        current
      end

      visit_number = ActsAsTenant.with_tenant(tenant) { current.visit_number }

      expect(visit_number).to eq(2)
    end

    it "skips the client's no-shows and keeps her completed visits" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      current = ActsAsTenant.with_tenant(tenant) do
        current = create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
        create(:appointment, :completed, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 25, 9, 45))
        create(:appointment, :no_show, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 8, 11, 9, 45))
        current
      end

      visit_number = ActsAsTenant.with_tenant(tenant) { current.visit_number }

      expect(visit_number).to eq(2)
    end

    it "ignores later appointments and other clients" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      client = create(:client, tenant: tenant)
      another_client = create(:client, tenant: tenant)
      current = ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 22, 9, 45))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: another_client, starts_at: Time.zone.local(2026, 8, 25, 9, 45))
        create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
      end

      visit_number = ActsAsTenant.with_tenant(tenant) { current.visit_number }

      expect(visit_number).to eq(1)
    end

    it "counts only within the current tenant" do
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze, duration_minutes: 45)
      ze_client = create(:client, tenant: ze, phone: "11988771234")
      ActsAsTenant.with_tenant(ze) { create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, client: ze_client, starts_at: Time.zone.local(2026, 8, 25, 9, 45)) }
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      aurora_client = create(:client, tenant: aurora, phone: "11988771234")
      current = ActsAsTenant.with_tenant(aurora) { create(:appointment, tenant: aurora, professional: aurora_professional, service: aurora_service, client: aurora_client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

      visit_number = ActsAsTenant.with_tenant(aurora) { current.visit_number }

      expect(visit_number).to eq(1)
    end
  end
end
