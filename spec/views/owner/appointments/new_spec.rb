require "rails_helper"

RSpec.describe Views::Owner::Appointments::New, type: :component do
  it "paints the new-appointment screen with theme-aware tokens only" do
    tenant = create(:tenant, name: "Mary Sombracelhas")
    professional = build(:professional, tenant: tenant)
    branding = build(:branding, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Design com henna", duration_minutes: 60)
    day = Date.current

    html = Nokogiri::HTML5(render_phlex(described_class.new(
      tenant: tenant, branding: branding, professional: professional, services: [ service ], service: service, published: true,
      days: Appointment.booking_window.to_a, reasons: { day => :bookable }, selected_day: day,
      slots: [ day.in_time_zone.change(hour: 9) ], taken_slots: [], reason: :bookable
    ))).at_css("body").to_html

    expect(html).to include("bg-surface")
    expect(html).to include("text-ink")
    expect(html).to include("text-on-brand")
    expect(html).not_to match(/#[0-9a-f]{6}/i)
    expect(html).not_to include("rgb(")
    expect(html).not_to include("text-white")
  end
end
