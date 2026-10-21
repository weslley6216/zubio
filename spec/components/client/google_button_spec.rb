require "rails_helper"

RSpec.describe Components::Client::GoogleButton, type: :component do
  it "links to the given href with the Google label" do
    html = described_class.new(href: "/x").call

    link = Nokogiri::HTML5.fragment(html).at_css("a[data-google-button]")
    expect(link["href"]).to eq("/x")
    expect(link.text).to eq("Continuar com o Google")
  end
end
