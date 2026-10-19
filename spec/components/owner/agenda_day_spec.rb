require "rails_helper"

RSpec.describe Components::Owner::AgendaDay, type: :component do
  it "flags only the appointments in the out-of-hours set" do
    tenant = create(:tenant)
    branding = create(:branding, tenant: tenant)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    in_hours_client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    out_of_hours_client = create(:client, tenant: tenant, name: "Camila Nunes")
    day = Date.current
    in_hours_appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional, service: service, client: in_hours_client, starts_at: day.in_time_zone.change(hour: 9, min: 45))
    end
    out_of_hours_appointment = ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional, service: service, client: out_of_hours_client, starts_at: day.in_time_zone.change(hour: 18, min: 30))
    end

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, day: day,
      appointments: [ in_hours_appointment, out_of_hours_appointment ], out_of_hours: Set[ out_of_hours_appointment ]))
    fragment = Nokogiri::HTML5.fragment(html)
    in_hours_row = fragment.at_css(%(div[data-appointment-id="#{in_hours_appointment.id}"]))
    out_of_hours_row = fragment.at_css(%(div[data-appointment-id="#{out_of_hours_appointment.id}"]))

    expect(in_hours_row.text).to include("Confirmado")
    expect(in_hours_row["class"]).not_to include("border-danger")
    expect(out_of_hours_row.text).to include("Fora do expediente")
    expect(out_of_hours_row["class"]).to include("border-danger")
  end
end
