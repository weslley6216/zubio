require "rails_helper"

RSpec.describe Components::Owner::Appointments::ClientSearch, type: :component do
  it "wraps the matches in a busy-fade marker" do
    tenant = create(:tenant)
    client = create(:client, tenant: tenant, name: "Camila Nunes", phone: "11988771234")

    html = render_phlex(described_class.new(matches: [ client ], query: "camila"))
    fragment = Nokogiri::HTML5.fragment(html)

    fade = fragment.at_css("[data-busy-fade]")
    expect(fade).not_to be_nil
    expect(fade.text).to include("Camila Nunes")
  end
end
