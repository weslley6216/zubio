require "rails_helper"

RSpec.describe Components::Form::ColorSwatches, type: :component do
  def swatches_for(selected, blank_label: nil)
    described_class.new(
      label: "Cor da marca",
      name: "branding[brand_600]",
      custom_name: "branding[brand_600_custom]",
      selected: selected,
      blank_label: blank_label
    ).call
  end

  it "shows every swatch of the palette as a radio in one labelled group" do
    html = swatches_for(Branding::Palette.swatches.first)

    expect(html).to include("<legend")
    expect(html).to include("Cor da marca")
    Branding::Palette.swatches.each { |hex| expect(html).to include(%(value="#{hex}")) }
  end

  it "marks the swatch that matches the current color and leaves the others unmarked" do
    current = Branding::Palette.swatches.first
    other = Branding::Palette.swatches.last

    html = swatches_for(current)

    expect(html).to include(%(value="#{current}" checked))
    expect(html).not_to include(%(value="#{other}" checked))
  end

  it "keeps the typed code behind a closed disclosure when the current color is a swatch" do
    html = swatches_for(Branding::Palette.swatches.first)

    expect(html).to include("<details>")
    expect(html).to include(described_class::CUSTOM_SUMMARY)
    expect(html).to include(%(name="branding[brand_600_custom]"))
  end

  it "opens the disclosure and carries the code when the current color is not on the palette" do
    html = swatches_for("#123456")

    expect(html).to include("<details open>")
    expect(html).to include(%(value="#123456"))
    expect(html).to include(%(value="#{Branding::CUSTOM_COLOR_CHOICE}" checked))
  end

  it "offers no way to choose nothing when it is not told a blank label" do
    html = swatches_for(Branding::Palette.swatches.first)

    expect(html).not_to include(%(value="" checked))
  end

  it "offers a marked blank choice when it is told a blank label and nothing is selected" do
    html = swatches_for(nil, blank_label: "Igual à cor da marca")

    expect(html).to include("Igual à cor da marca")
    expect(html).to include(%(value="" checked))
  end

  it "paints each swatch through the served palette sheet, never an inline style attribute" do
    html = swatches_for(Branding::Palette.swatches.first)

    expect(html).to include(%(data-swatch="#{Branding::Palette.swatches.first}"))
    expect(html).not_to include("style=")
  end

  it "reaches the touch target the design system asks of an interactive cell" do
    html = swatches_for(Branding::Palette.swatches.first)

    expect(html).to include("h-11 w-11")
  end
end
