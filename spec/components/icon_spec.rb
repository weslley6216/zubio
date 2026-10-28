require "rails_helper"

RSpec.describe Components::Icon, type: :component do
  it "renders a 24-grid svg with currentColor stroke, round caps and aria-hidden" do
    svg = Nokogiri::HTML5.fragment(described_class.new(:chevron_left).call).at_css("svg")

    expect(svg["viewBox"]).to eq("0 0 24 24")
    expect(svg["fill"]).to eq("none")
    expect(svg["stroke"]).to eq("currentColor")
    expect(svg["stroke-linecap"]).to eq("round")
    expect(svg["stroke-linejoin"]).to eq("round")
    expect(svg["aria-hidden"]).to eq("true")
  end

  it "tags the svg with the dasherized Lucide name" do
    svg = Nokogiri::HTML5.fragment(described_class.new(:chevron_left).call).at_css("svg")

    expect(svg["data-icon"]).to eq("chevron-left")
  end

  it "passes the given class through to the svg" do
    svg = Nokogiri::HTML5.fragment(described_class.new(:chevron_left, class: "h-5 w-5").call).at_css("svg")

    expect(svg["class"]).to eq("h-5 w-5")
  end

  it "passes the given stroke-width through" do
    svg = Nokogiri::HTML5.fragment(described_class.new(:chevron_left, stroke_width: "2.5").call).at_css("svg")

    expect(svg["stroke-width"]).to eq("2.5")
  end

  it "defaults the stroke-width to 2" do
    svg = Nokogiri::HTML5.fragment(described_class.new(:chevron_left).call).at_css("svg")

    expect(svg["stroke-width"]).to eq("2")
  end

  it "draws the canonical Lucide geometry, not the old hand-drawn path" do
    svg = Nokogiri::HTML5.fragment(described_class.new(:chevron_left).call).at_css("svg")

    expect(svg.to_html).to include(%(d="m15 18-6-6 6-6"))
    expect(svg.to_html).not_to include(%(d="m15 6-6 6 6 6"))
  end

  it "renders every catalogued icon with its matching data hook" do
    described_class::CATALOG.each_key do |name|
      svg = Nokogiri::HTML5.fragment(described_class.new(name).call).at_css("svg")

      expect(svg["data-icon"]).to eq(name.to_s.tr("_", "-"))
      expect(svg.children).not_to be_empty
    end
  end

  it "raises for an unknown icon name" do
    expect { described_class.new(:nope).call }.to raise_error(KeyError)
  end
end
