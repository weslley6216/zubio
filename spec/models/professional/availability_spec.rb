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
end
