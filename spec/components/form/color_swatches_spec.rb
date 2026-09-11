require "rails_helper"

RSpec.describe Components::Form::ColorSwatches, type: :component do
  def brand_swatches(selected, fallback: Branding::DEFAULT_BRAND_600)
    described_class.new(label: "Cor da marca", attribute: :brand_600, selected: selected, fallback: fallback).call
  end

  def secondary_swatches(selected, fallback:)
    described_class.new(label: "Cor secundária", attribute: :brand_secondary_600, selected: selected,
      fallback: fallback, linked_label: "Igual à marca").call
  end

  it "shows every swatch of the palette as a radio in one labelled group" do
    html = brand_swatches(Branding::Palette.swatches.first)

    expect(html).to include("<legend")
    expect(html).to include("Cor da marca")
    Branding::Palette.swatches.each { |hex| expect(html).to include(%(value="#{hex}")) }
  end

  it "packs the palette into a grid of eight columns" do
    html = brand_swatches(Branding::Palette.swatches.first)

    expect(html).to include("grid-cols-8")
  end

  it "names the group by the field alone, so the code it reads back never becomes the group's name" do
    html = brand_swatches("#4F46E5")

    expect(html).to include(%(<fieldset aria-label="Cor da marca"))
    expect(html).to include(%(data-color-swatch-target="code">#4F46E5<))
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
    html = secondary_swatches(nil, fallback: "#4F46E5")

    expect(html).to include("bg-secondary-600")
    expect(html).not_to include("bg-brand-600")
  end

  it "falls back to the platform color when the record carries no color to read back" do
    html = brand_swatches(nil, fallback: nil)

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

  it "starts linked, with the grid and the code it reads back both folded away, when nothing of its own is stored" do
    html = secondary_swatches(nil, fallback: "#4F46E5")

    expect(html).to include("Igual à marca")
    expect(html).to include(%(value="" checked))
    expect(html).to include(%(hidden data-color-swatch-target="panel"))
    expect(html).to include(%(hidden data-color-swatch-target="readout"))
    expect(html).to include(%(aria-expanded="false"))
  end

  it "starts on its own color, with the grid and the code it reads back both unfolded, when one is stored" do
    current = Branding::Palette.swatches.last

    html = secondary_swatches(current, fallback: "#4F46E5")

    expect(html).not_to include(%(value="" checked))
    expect(html).not_to include(%(hidden data-color-swatch-target="panel"))
    expect(html).not_to include(%(hidden data-color-swatch-target="readout"))
    expect(html).to include(%(aria-expanded="true"))
  end

  it "points each disclosure at the panel it opens, and says whether that panel is open" do
    html = secondary_swatches(nil, fallback: "#4F46E5")

    expect(html).to include(%(aria-controls="brand_secondary_600-palette"))
    expect(html).to include(%(id="brand_secondary_600-palette"))
    expect(html).to include(%(aria-controls="brand_secondary_600-code"))
    expect(html).to include(%(id="brand_secondary_600-code"))
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
