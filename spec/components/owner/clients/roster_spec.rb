require "rails_helper"

RSpec.describe Components::Owner::Clients::Roster, type: :component do
  it "wraps the client list in a busy-fade marker" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Camila Nunes")
    entry = Client::Roster::Entry.new(client: client, next_visit_at: nil, last_visit_at: nil, visit_count: 0)

    html = render_phlex(described_class.new(entries: [ entry ], total: 1, tenant: tenant))
    fragment = Nokogiri::HTML5.fragment(html)

    fade = fragment.at_css("[data-busy-fade]")
    expect(fade).not_to be_nil
    expect(fade.text).to include("Camila Nunes")
  end

  it "wraps the empty state in a busy-fade marker too" do
    tenant = create(:tenant, name: "Estúdio Aurora")

    html = render_phlex(described_class.new(entries: [], total: 0, tenant: tenant))
    fragment = Nokogiri::HTML5.fragment(html)

    fade = fragment.at_css("[data-busy-fade]")
    expect(fade).not_to be_nil
    expect(fade.text).to include(described_class::EMPTY_TITLE)
  end
end
