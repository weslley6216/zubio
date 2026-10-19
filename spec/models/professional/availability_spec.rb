require "rails_helper"

RSpec.describe Professional::Availability, type: :model do
  it "offers the full grid when the day is open and empty" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    nine = tuesday.in_time_zone.change(hour: 9)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).to eq([ nine, nine + 45.minutes, nine + 90.minutes, nine + 135.minutes ])
  end

  it "never offers a candidate that spills past the window" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    noon = tuesday.in_time_zone.change(hour: 12)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).not_to include(noon)
    expect(slots[tuesday]).to all(satisfy { |candidate| candidate + 45.minutes <= noon })
  end

  it "anchors each window of the day independently" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "14:00", closes_at: "18:00")
    two_pm = tuesday.in_time_zone.change(hour: 14)
    gap = tuesday.in_time_zone.change(hour: 12)...two_pm

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).to include(two_pm)
    expect(slots[tuesday]).not_to include(be_in(gap))
  end

  it "uses the service duration as the grid step" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 30)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    nine = tuesday.in_time_zone.change(hour: 9)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).to eq((0..5).map { |step| nine + (step * 30).minutes })
  end

  it "includes a weekday without working hours as an empty list" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    wednesday = Date.current.next_week(:wednesday)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: wednesday..wednesday).slots_by_date }

    expect(slots).to have_key(wednesday)
    expect(slots[wednesday]).to be_empty
  end

  it "returns one entry per day across a multi-day window" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    [ 2, 3, 4 ].each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "12:00") }
    window = tuesday..(tuesday + 6)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: window).slots_by_date }

    expect(slots.keys).to eq(window.to_a)
    expect(window.select { |date| slots[date].any? }).to eq([ tuesday, tuesday + 1, tuesday + 2 ])
  end

  it "drops colliding candidates without shifting the following ones" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    occupying_service = create(:service, tenant: tenant, duration_minutes: 30)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
    create(:appointment, tenant: tenant, professional: professional, service: occupying_service, starts_at: tuesday.in_time_zone.change(hour: 10, min: 15))
    nine = tuesday.in_time_zone.change(hour: 9)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).to include(nine, nine + 135.minutes)
    expect(slots[tuesday]).not_to include(nine + 45.minutes, nine + 90.minutes, tuesday.in_time_zone.change(hour: 10, min: 45))
  end

  it "ignores a cancelled appointment" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 9))
    nine = tuesday.in_time_zone.change(hour: 9)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).to include(nine)
  end

  it "keeps a completed appointment's slot taken" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:appointment, :completed, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 9, min: 45))
    nine = tuesday.in_time_zone.change(hour: 9)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).not_to include(tuesday.in_time_zone.change(hour: 9, min: 45))
    expect(slots[tuesday]).to include(nine)
  end

  it "keeps a no-show's slot taken" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:appointment, :no_show, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 9, min: 45))
    nine = tuesday.in_time_zone.change(hour: 9)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).not_to include(tuesday.in_time_zone.change(hour: 9, min: 45))
    expect(slots[tuesday]).to include(nine)
  end

  it "zeroes a day closed by a full-day exception" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
    create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: tuesday)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).to be_empty
  end

  it "lets an open exception replace the weekday hours" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    saturday = Date.current.next_week(:saturday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 6, opens_at: "09:00", closes_at: "18:00")
    create(:schedule_exception, :with_alternate_hours, tenant: tenant, professional: professional, occurs_on: saturday)
    nine = saturday.in_time_zone.change(hour: 9)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: saturday..saturday).slots_by_date }

    expect(slots[saturday]).to eq([ nine, nine + 45.minutes, nine + 90.minutes, nine + 135.minutes ])
  end

  it "never offers a time in the past" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    today = Date.current
    create(:working_hour, tenant: tenant, professional: professional, weekday: today.wday, opens_at: "09:00", closes_at: "18:00")
    three_pm = today.in_time_zone.change(hour: 15)

    slots = travel_to(three_pm) { ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: today..today).slots_by_date } }

    expect(slots[today]).to all(be >= three_pm)
    expect(slots[today].first).to eq(three_pm)
  end

  it "does not let another tenant's appointment block a slot" do
    aurora = create(:tenant, name: "Estúdio Aurora")
    aurora_professional = create(:professional, tenant: aurora)
    aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: aurora, professional: aurora_professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    ze = create(:tenant, name: "Barbearia do Zé")
    ze_professional = create(:professional, tenant: ze)
    ze_service = create(:service, tenant: ze, duration_minutes: 45)
    create(:working_hour, tenant: ze, professional: ze_professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, starts_at: tuesday.in_time_zone.change(hour: 9))
    nine = tuesday.in_time_zone.change(hour: 9)

    slots = ActsAsTenant.with_tenant(aurora) { described_class.new(professional: aurora_professional, service: aurora_service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).to include(nine)
  end

  it "does not let a colleague's appointment or day off block a slot" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    colleague = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:appointment, tenant: tenant, professional: colleague, service: service, starts_at: tuesday.in_time_zone.change(hour: 9))
    create(:schedule_exception, tenant: tenant, professional: colleague, occurs_on: tuesday)
    nine = tuesday.in_time_zone.change(hour: 9)

    slots = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date }

    expect(slots[tuesday]).to eq([ nine, nine + 45.minutes, nine + 90.minutes, nine + 135.minutes ])
  end

  it "runs the same number of queries for thirty days as for one" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
    create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: tuesday + 7)
    create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 10))

    one = ActsAsTenant.with_tenant(tenant) { count_queries { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).slots_by_date } }
    thirty = ActsAsTenant.with_tenant(tenant) { count_queries { described_class.new(professional: professional, service: service, dates: tuesday..(tuesday + 29)).slots_by_date } }

    expect(thirty).to eq(one)
  end

  describe "#taken_slots_by_date" do
    it "lists the future candidates an appointment occupies" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = tuesday.in_time_zone.change(hour: 9)
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: nine + 45.minutes)

      taken = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).taken_slots_by_date }

      expect(taken[tuesday]).to eq([ nine + 45.minutes ])
    end

    it "leaves a past candidate out even when it was taken" do
      travel_to Time.zone.local(2026, 9, 8, 10, 0)
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: Time.zone.local(2026, 9, 8, 9, 0))
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: Time.zone.local(2026, 9, 8, 10, 30))

      taken = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).taken_slots_by_date }

      expect(taken[tuesday]).to eq([ Time.zone.local(2026, 9, 8, 10, 30) ])
    end

    it "does not count another tenant's appointment as taken" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: aurora, professional: aurora_professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      create(:appointment, tenant: aurora, professional: aurora_professional, service: aurora_service, starts_at: tuesday.in_time_zone.change(hour: 10, min: 30))
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze, duration_minutes: 45)
      create(:working_hour, tenant: ze, professional: ze_professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, starts_at: tuesday.in_time_zone.change(hour: 9))

      taken = ActsAsTenant.with_tenant(aurora) { described_class.new(professional: aurora_professional, service: aurora_service, dates: tuesday..tuesday).taken_slots_by_date }

      expect(taken[tuesday]).to eq([ tuesday.in_time_zone.change(hour: 10, min: 30) ])
    end
  end

  describe "#reasons_by_date" do
    it "marks an open day with free slots as bookable" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")

      reasons = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).reasons_by_date }

      expect(reasons[tuesday]).to eq(:bookable)
    end

    it "marks a weekday without working hours as no_working_day" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      wednesday = Date.current.next_week(:wednesday)

      reasons = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: wednesday..wednesday).reasons_by_date }

      expect(reasons[wednesday]).to eq(:no_working_day)
    end

    it "marks a day closed by a full-day exception as day_off" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: tuesday)

      reasons = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).reasons_by_date }

      expect(reasons[tuesday]).to eq(:day_off)
    end

    it "marks an open day with no free slot left as fully_booked" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "09:45")
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 9))

      reasons = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).reasons_by_date }

      expect(reasons[tuesday]).to eq(:fully_booked)
    end

    it "marks today as fully_booked once its working hours are over" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")

      reasons = travel_to(tuesday.in_time_zone.change(hour: 15)) { ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).reasons_by_date } }

      expect(reasons[tuesday]).to eq(:fully_booked)
    end

    it "does not let another tenant's appointment turn a bookable day into fully_booked" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: aurora, professional: aurora_professional, weekday: 2, opens_at: "09:00", closes_at: "09:45")
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze, duration_minutes: 45)
      create(:working_hour, tenant: ze, professional: ze_professional, weekday: 2, opens_at: "09:00", closes_at: "09:45")
      create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, starts_at: tuesday.in_time_zone.change(hour: 9))

      reasons = ActsAsTenant.with_tenant(aurora) { described_class.new(professional: aurora_professional, service: aurora_service, dates: tuesday..tuesday).reasons_by_date }

      expect(reasons[tuesday]).to eq(:bookable)
    end

    it "runs the same number of queries for thirty days as for one" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: tuesday + 7)
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 10))

      one = ActsAsTenant.with_tenant(tenant) { count_queries { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).reasons_by_date } }
      thirty = ActsAsTenant.with_tenant(tenant) { count_queries { described_class.new(professional: professional, service: service, dates: tuesday..(tuesday + 29)).reasons_by_date } }

      expect(thirty).to eq(one)
    end
  end

  describe "#appointments_outside_hours" do
    it "reports an appointment that ends after the window closes" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 17, min: 30))

      conflicts = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).appointments_outside_hours }

      expect(conflicts).to include(appointment)
    end

    it "keeps an appointment fully inside the window out of the warning" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 14))

      conflicts = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).appointments_outside_hours }

      expect(conflicts).to be_empty
    end

    it "reports an appointment that straddles the midday break" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 60)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "12:00")
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "14:00", closes_at: "18:00")
      appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 11, min: 30))

      conflicts = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).appointments_outside_hours }

      expect(conflicts).to include(appointment)
    end

    it "reports every appointment of a day closed by a full-day exception" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: friday)
      appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 10))

      conflicts = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).appointments_outside_hours }

      expect(conflicts).to include(appointment)
    end

    it "ignores a cancelled appointment" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "12:00")
      create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 17))
      confirmed = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 17, min: 30))

      conflicts = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).appointments_outside_hours }

      expect(conflicts).to eq([ confirmed ])
    end

    it "ignores an appointment already in the past" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      next_friday = friday + 7
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "12:00")
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 17))
      future = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: next_friday.in_time_zone.change(hour: 17))

      conflicts = travel_to(friday.in_time_zone.change(hour: 20)) { ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).appointments_outside_hours } }

      expect(conflicts).to eq([ future ])
    end

    it "orders the reported appointments by start time" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      next_friday = friday + 7
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "12:00")
      later = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: next_friday.in_time_zone.change(hour: 17))
      earlier = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 17))

      conflicts = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).appointments_outside_hours }

      expect(conflicts).to eq([ earlier, later ])
    end

    it "never reports an appointment from another tenant" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: aurora, professional: aurora_professional, weekday: 5, opens_at: "09:00", closes_at: "12:00")
      aurora_appointment = create(:appointment, tenant: aurora, professional: aurora_professional, service: aurora_service, starts_at: friday.in_time_zone.change(hour: 17))
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze, duration_minutes: 45)
      create(:working_hour, tenant: ze, professional: ze_professional, weekday: 5, opens_at: "09:00", closes_at: "12:00")
      create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, starts_at: friday.in_time_zone.change(hour: 17))

      conflicts = ActsAsTenant.with_tenant(aurora) { described_class.new(professional: aurora_professional).appointments_outside_hours }

      expect(conflicts).to eq([ aurora_appointment ])
    end

    it "reports outside appointments in the same number of queries for one as for many" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "12:00")
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 17))

      one = ActsAsTenant.with_tenant(tenant) { count_queries { described_class.new(professional: professional).appointments_outside_hours } }
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: (friday + 7).in_time_zone.change(hour: 17))
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: (friday + 14).in_time_zone.change(hour: 17))
      many = ActsAsTenant.with_tenant(tenant) { count_queries { described_class.new(professional: professional).appointments_outside_hours } }

      expect(many).to eq(one)
    end
  end

  describe "#schedule_published?" do
    it "is true when the professional has working hours" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      tuesday = Date.current.next_week(:tuesday)

      published = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).schedule_published? }

      expect(published).to be(true)
    end

    it "is false when the professional has no working hours" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)

      published = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).schedule_published? }

      expect(published).to be(false)
    end
  end

  describe "#open_until" do
    it "returns the closing time when the moment falls inside the open window" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      ten = tuesday.in_time_zone.change(hour: 10)
      closing = tuesday.in_time_zone.change(hour: 18)

      open_until = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).open_until(ten) }

      expect(open_until).to eq(closing)
    end

    it "returns nil before the window opens" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      eight = tuesday.in_time_zone.change(hour: 8)

      open_until = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).open_until(eight) }

      expect(open_until).to be_nil
    end

    it "returns the closing time at the exact opening moment" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      nine = tuesday.in_time_zone.change(hour: 9)
      closing = tuesday.in_time_zone.change(hour: 18)

      open_until = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).open_until(nine) }

      expect(open_until).to eq(closing)
    end

    it "returns nil after the window closes" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      eight_pm = tuesday.in_time_zone.change(hour: 20)

      open_until = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).open_until(eight_pm) }

      expect(open_until).to be_nil
    end

    it "returns the last closing of the day across a midday break" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "14:00", closes_at: "19:00")
      ten = tuesday.in_time_zone.change(hour: 10)
      seven_pm = tuesday.in_time_zone.change(hour: 19)

      open_until = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).open_until(ten) }

      expect(open_until).to eq(seven_pm)
    end

    it "returns nil at the exact closing moment" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      closing = tuesday.in_time_zone.change(hour: 18)

      open_until = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).open_until(closing) }

      expect(open_until).to be_nil
    end

    it "returns nil on a weekday without working hours" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      wednesday = Date.current.next_week(:wednesday)
      ten = wednesday.in_time_zone.change(hour: 10)

      open_until = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).open_until(ten) }

      expect(open_until).to be_nil
    end

    it "returns nil on a day closed by a full-day exception" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: tuesday)
      ten = tuesday.in_time_zone.change(hour: 10)

      open_until = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).open_until(ten) }

      expect(open_until).to be_nil
    end

    it "returns the alternate closing time when an exception replaces the weekday hours" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      saturday = Date.current.next_week(:saturday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 6, opens_at: "09:00", closes_at: "18:00")
      create(:schedule_exception, :with_alternate_hours, tenant: tenant, professional: professional, occurs_on: saturday)
      ten = saturday.in_time_zone.change(hour: 10)
      noon = saturday.in_time_zone.change(hour: 12)

      open_until = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional).open_until(ten) }

      expect(open_until).to eq(noon)
    end

    it "reflects only the host tenant's working hours, not another tenant's" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: aurora, professional: aurora_professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      create(:working_hour, tenant: ze, professional: ze_professional, weekday: 2, opens_at: "09:00", closes_at: "20:00")
      ten = tuesday.in_time_zone.change(hour: 10)
      closing = tuesday.in_time_zone.change(hour: 18)

      open_until = ActsAsTenant.with_tenant(aurora) { described_class.new(professional: aurora_professional).open_until(ten) }

      expect(open_until).to eq(closing)
    end

    it "sees none of another tenant's working hours under the host tenant" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      tuesday = Date.current.next_week(:tuesday)
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      create(:working_hour, tenant: ze, professional: ze_professional, weekday: 2, opens_at: "09:00", closes_at: "20:00")
      ten = tuesday.in_time_zone.change(hour: 10)

      open_until = ActsAsTenant.with_tenant(aurora) { described_class.new(professional: ze_professional).open_until(ten) }

      expect(open_until).to be_nil
    end
  end

  describe "#offers?" do
    it "offers a free candidate on the grid" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = tuesday.in_time_zone.change(hour: 9)

      offered = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).offers?(nine) }

      expect(offered).to be(true)
    end

    it "offers a taken candidate that is still on the grid" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine_forty_five = tuesday.in_time_zone.change(hour: 9, min: 45)
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: nine_forty_five)

      offered = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).offers?(nine_forty_five) }

      expect(offered).to be(true)
    end

    it "does not offer a time off the grid step" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      off_step = tuesday.in_time_zone.change(hour: 9, min: 50)

      offered = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).offers?(off_step) }

      expect(offered).to be(false)
    end

    it "does not offer a time outside the working hours" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      dawn = tuesday.in_time_zone.change(hour: 3)

      offered = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).offers?(dawn) }

      expect(offered).to be(false)
    end

    it "does not offer a time in the past" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      today = Date.current
      create(:working_hour, tenant: tenant, professional: professional, weekday: today.wday, opens_at: "09:00", closes_at: "18:00")
      nine = today.in_time_zone.change(hour: 9)

      offered = travel_to(today.in_time_zone.change(hour: 15)) { ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: today..today).offers?(nine) } }

      expect(offered).to be(false)
    end

    it "does not offer a nil moment" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")

      offered = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).offers?(nil) }

      expect(offered).to be(false)
    end

    it "still offers a slot another tenant booked at the same time" do
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: aurora, professional: aurora_professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze, duration_minutes: 45)
      create(:working_hour, tenant: ze, professional: ze_professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = tuesday.in_time_zone.change(hour: 9)
      create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, starts_at: nine)

      offered = ActsAsTenant.with_tenant(aurora) { described_class.new(professional: aurora_professional, service: aurora_service, dates: tuesday..tuesday).offers?(nine) }

      expect(offered).to be(true)
    end
  end

  describe "#nearest_free" do
    it "returns the free slot closest to the given moment, skipping the taken ones" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      nine = tuesday.in_time_zone.change(hour: 9)
      nine_forty_five = tuesday.in_time_zone.change(hour: 9, min: 45)
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: nine)
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: nine_forty_five)

      nearest = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).nearest_free(nine_forty_five) }

      expect(nearest).to eq(tuesday.in_time_zone.change(hour: 10, min: 30))
    end

    it "returns nil when the day has no free slot left" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "09:45")
      nine = tuesday.in_time_zone.change(hour: 9)
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: nine)

      nearest = ActsAsTenant.with_tenant(tenant) { described_class.new(professional: professional, service: service, dates: tuesday..tuesday).nearest_free(nine) }

      expect(nearest).to be_nil
    end
  end

  describe "#outside_hours" do
    it "flags an appointment that starts after the window closes" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 18, min: 30))

      outside = ActsAsTenant.with_tenant(tenant) do
        appointments = Appointment.for_day(friday)
        described_class.new(professional: professional, dates: friday..friday).outside_hours(appointments)
      end

      expect(outside).to include(appointment)
    end

    it "keeps an appointment fully inside the window unflagged" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 14))

      outside = ActsAsTenant.with_tenant(tenant) do
        appointments = Appointment.for_day(friday)
        described_class.new(professional: professional, dates: friday..friday).outside_hours(appointments)
      end

      expect(outside).to be_empty
    end

    it "flags an appointment that runs past the closing time" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 17, min: 30))

      outside = ActsAsTenant.with_tenant(tenant) do
        appointments = Appointment.for_day(friday)
        described_class.new(professional: professional, dates: friday..friday).outside_hours(appointments)
      end

      expect(outside).to include(appointment)
    end

    it "flags every appointment on a day closed by a full-day exception" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
      create(:schedule_exception, tenant: tenant, professional: professional, occurs_on: tuesday)
      first_appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 10))
      second_appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: tuesday.in_time_zone.change(hour: 14))

      outside = ActsAsTenant.with_tenant(tenant) do
        appointments = Appointment.for_day(tuesday)
        described_class.new(professional: professional, dates: tuesday..tuesday).outside_hours(appointments)
      end

      expect(outside).to contain_exactly(first_appointment, second_appointment)
    end

    it "never flags a cancelled appointment" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 18, min: 30))
      confirmed = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 19, min: 30))

      outside = ActsAsTenant.with_tenant(tenant) do
        appointments = Appointment.for_day(friday)
        described_class.new(professional: professional, dates: friday..friday).outside_hours(appointments)
      end

      expect(outside).to eq([ confirmed ])
    end

    it "never flags an appointment already in the past" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 18, min: 30))
      future = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: (friday + 7).in_time_zone.change(hour: 18, min: 30))

      outside = travel_to(friday.in_time_zone.change(hour: 20)) do
        ActsAsTenant.with_tenant(tenant) do
          appointments = Appointment.for_day(friday) + Appointment.for_day(friday + 7)
          described_class.new(professional: professional, dates: friday..(friday + 7)).outside_hours(appointments)
        end
      end

      expect(outside).to eq([ future ])
    end

    it "reports flagged appointments in the same number of queries for many as for one" do
      tenant = create(:tenant)
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 18, min: 30))

      one = ActsAsTenant.with_tenant(tenant) do
        appointments = Appointment.for_day(friday)
        count_queries { described_class.new(professional: professional, dates: friday..friday).outside_hours(appointments) }
      end

      ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 19, min: 30))
        create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: friday.in_time_zone.change(hour: 20, min: 30))
      end
      many = ActsAsTenant.with_tenant(tenant) do
        appointments = Appointment.for_day(friday)
        count_queries { described_class.new(professional: professional, dates: friday..friday).outside_hours(appointments) }
      end

      expect(many).to eq(one)
    end

    it "uses only the host tenant's working hours" do
      ze = create(:tenant, name: "Barbearia do Zé")
      ze_professional = create(:professional, tenant: ze)
      ze_service = create(:service, tenant: ze, duration_minutes: 45)
      friday = Date.current.next_week(:friday)
      create(:working_hour, tenant: ze, professional: ze_professional, weekday: 5, opens_at: "09:00", closes_at: "20:00")
      create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, starts_at: friday.in_time_zone.change(hour: 18, min: 30))
      aurora = create(:tenant, name: "Estúdio Aurora")
      aurora_professional = create(:professional, tenant: aurora)
      aurora_service = create(:service, tenant: aurora, duration_minutes: 45)
      create(:working_hour, tenant: aurora, professional: aurora_professional, weekday: 5, opens_at: "09:00", closes_at: "18:00")
      aurora_appointment = create(:appointment, tenant: aurora, professional: aurora_professional, service: aurora_service, starts_at: friday.in_time_zone.change(hour: 18, min: 30))

      outside = ActsAsTenant.with_tenant(aurora) do
        appointments = Appointment.for_day(friday)
        described_class.new(professional: aurora_professional, dates: friday..friday).outside_hours(appointments)
      end

      expect(outside).to eq([ aurora_appointment ])
    end
  end
end
