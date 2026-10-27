require "rails_helper"

RSpec.describe Components::Owner::AppointmentDetailFrame, type: :component do
  it "renders a lg-only skeleton for the detail panel" do
    html = render_phlex(described_class.new)
    fragment = Nokogiri::HTML5.fragment(html)

    skeleton = fragment.at_css("[data-skeleton][aria-hidden='true']")
    expect(skeleton).not_to be_nil
    expect(skeleton["class"]).to include("hidden")
    expect(skeleton["class"]).to include("lg:grid")
  end
end
