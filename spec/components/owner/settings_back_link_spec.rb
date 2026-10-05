require "rails_helper"

RSpec.describe Components::Owner::SettingsBackLink, type: :component do
  it "links back to settings with the label and the left chevron" do
    html = render_phlex(described_class.new)

    link = Nokogiri::HTML5.fragment(html).at_css("a")
    expect(link["href"]).to eq("/owner/settings")
    expect(link.text).to include("Configurações")
    expect(html).to include(described_class::ICON)
  end

  it "wears the muted back treatment" do
    html = render_phlex(described_class.new)

    expect(Nokogiri::HTML5.fragment(html).at_css("a")["class"]).to include("text-ink-muted")
  end
end
