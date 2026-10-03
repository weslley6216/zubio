require "rails_helper"

RSpec.describe Components::Owner::SettingsBackLink, type: :component do
  def body = render_phlex(described_class.new)

  it "links back to settings with the label and the left chevron" do
    html = body
    document = Nokogiri::HTML5.fragment(html)

    expect(document.at_css("a")["href"]).to eq("/owner/settings")
    expect(document.at_css("a").text).to include("Configurações")
    expect(html).to include(described_class::ICON)
  end

  it "wears the muted back treatment" do
    document = Nokogiri::HTML5.fragment(body)

    expect(document.at_css("a")["class"]).to include("text-ink-muted")
  end
end
