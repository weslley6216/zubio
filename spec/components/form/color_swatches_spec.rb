require "rails_helper"

RSpec.describe Components::Form::ColorSwatches, type: :component do
  def brand_swatches(selected, resolved: selected)
    described_class.new(label: "Cor da marca", attribute: :brand_600, selected: selected, resolved: resolved).call
  end

  def secondary_swatches(selected, resolved:)
    described_class.new(label: "Cor secundária", attribute: :brand_secondary_600, selected: selected,
      resolved: resolved, linked_label: "Igual à marca").call
  end

  it "shows every swatch of the palette as a radio in one labelled group" do
    html = brand_swatches(Branding::Palette.swatches.first)

    expect(html).to include("<legend")
    expect(html).to include("Cor da marca")
    Branding::Palette.swatches.each { |hex| expect(html).to include(%(value="#{hex}")) }
  end

  it "packs the palette into one dense grid instead of the narrow stack that forced the screen to scroll" do
    html = brand_swatches(Branding::Palette.swatches.first)

    expect(html).to include("grid-cols-8")
    expect(html).not_to include("grid-cols-4")
  end

  it "marks the swatch that matches the current color and leaves the others unmarked" do
    current = Branding::Palette.swatches.first
    other = Branding::Palette.swatches.last

    html = brand_swatches(current)

    expect(html).to include(%(value="#{current}" checked))
    expect(html).not_to include(%(value="#{other}" checked))
  end

  it "marks the swatch even when the stored code is written in the other letter case" do
    html = brand_swatches(Branding::Palette.swatches.last.downcase)

    expect(html).to include(%(value="#{Branding::Palette.swatches.last}" checked))
  end

  it "reads the current color back as a code beside a chip painted by the field's own token" do
    html = brand_swatches("#4F46E5")

    expect(html).to include(%(data-color-swatch-target="code">#4F46E5<))
    expect(html).to include("bg-brand-600")
  end

  it "reads the secondary color back through the secondary token, never the brand one" do
    html = secondary_swatches(nil, resolved: "#4F46E5")

    expect(html).to include("bg-secondary-600")
    expect(html).not_to include("bg-brand-600")
  end

  it "falls back to the platform color when the record carries no color to read back" do
    html = brand_swatches(nil, resolved: nil)

    expect(html).to include(%(data-color-swatch-target="code">#{Branding::DEFAULT_BRAND_600}<))
  end

  it "keeps the typed code folded away when the current color is a swatch" do
    html = brand_swatches(Branding::Palette.swatches.first)

    expect(html).to include(%(hidden data-color-swatch-target="customPanel"))
    expect(html).to include(described_class::CUSTOM_SUMMARY)
    expect(html).to include(%(name="branding[brand_600_custom]"))
  end

  it "unfolds the typed code and carries it when the current color is not on the palette" do
    html = brand_swatches("#123456")

    expect(html).not_to include(%(hidden data-color-swatch-target="customPanel"))
    expect(html).to include(%(value="#123456"))
    expect(html).to include(%(value="#{Branding::CUSTOM_COLOR_CHOICE}" checked))
  end

  it "offers no way to follow another color when it is not told a linked label" do
    html = brand_swatches(Branding::Palette.swatches.first)

    expect(html).not_to include(%(value="" checked))
    expect(html).not_to include(described_class::OWN_LABEL)
  end

  it "starts linked, with the grid folded away, when it is told a linked label and nothing of its own is stored" do
    html = secondary_swatches(nil, resolved: "#4F46E5")

    expect(html).to include("Igual à marca")
    expect(html).to include(%(value="" checked))
    expect(html).to include(%(hidden data-color-swatch-target="panel"))
    expect(html).to include(%(aria-pressed="false"))
  end

  it "starts on its own color, with the grid unfolded, when one is stored" do
    current = Branding::Palette.swatches.last

    html = secondary_swatches(current, resolved: current)

    expect(html).not_to include(%(value="" checked))
    expect(html).not_to include(%(hidden data-color-swatch-target="panel"))
    expect(html).to include(%(aria-pressed="true"))
  end

  it "paints each swatch through the served palette sheet, never an inline style attribute" do
    html = brand_swatches(Branding::Palette.swatches.first)

    expect(html).to include(%(data-swatch="#{Branding::Palette.swatches.first}"))
    expect(html).not_to include("style=")
  end

  it "reaches the touch target the design system asks of every control outside the swatch grid" do
    html = brand_swatches("#123456")

    expect(html).to include("h-11 w-11")
    expect(html).to include("min-h-11")
  end
end
