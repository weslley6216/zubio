require "rails_helper"

RSpec.describe "appointments schema", type: :model do
  it "enables the btree_gist extension" do
    expect(ActiveRecord::Base.connection.extensions).to include("btree_gist")
  end

  it "keeps the positive-duration check constraint" do
    names = ActiveRecord::Base.connection.check_constraints("appointments").map(&:name)

    expect(names).to include("appointments_positive_duration")
  end

  it "keeps the no-overlap exclusion constraint" do
    names = ActiveRecord::Base.connection.exclusion_constraints("appointments").map(&:name)

    expect(names).to include("appointments_no_overlap")
  end

  it "rejects an appointment without a client at the database level" do
    tenant = create(:tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    nine = Time.current.next_week(:tuesday).change(hour: 9, min: 0, sec: 0)
    appointment = ActsAsTenant.with_tenant(tenant) do
      Appointment.new(professional: professional, service: service, starts_at: nine, ends_at: nine + 45.minutes)
    end

    expect { ActsAsTenant.with_tenant(tenant) { appointment.save(validate: false) } }
      .to raise_error(ActiveRecord::NotNullViolation, /client_id/)
  end
end
