require "rails_helper"

RSpec.describe Components::Client::Bookings::Grid, type: :component do
  it "renders the real grid under a frame-content marker" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    slot = Time.zone.local(2026, 9, 8, 9, 0)

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(service: service, slots: [ slot ], taken_slots: [], reason: :bookable, selected_slot: nil)) }
    fragment = Nokogiri::HTML5.fragment(html)

    expect(fragment.at_css("[data-frame-content] [data-slots]")).not_to be_nil
  end

  it "renders a hidden skeleton of eight slots with the resting tokens" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)

    html = ActsAsTenant.with_tenant(tenant) { render_phlex(described_class.new(service: service, slots: [], taken_slots: [], reason: :bookable, selected_slot: nil)) }
    fragment = Nokogiri::HTML5.fragment(html)

    skeleton = fragment.at_css("[data-skeleton][aria-hidden='true']")
    expect(skeleton).not_to be_nil
    pieces = skeleton.css("> *")
    expect(pieces.size).to eq(8)
    pieces.each do |piece|
      expect(piece["class"]).to include("min-h-[46px]")
      expect(piece["class"]).to include("rounded-[10px]")
      expect(piece["class"]).to include("bg-surface-3")
      expect(piece["class"]).to include("motion-safe:animate-pulse")
    end
  end
end
