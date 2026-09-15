require "rails_helper"

RSpec.describe Components::ColorChip, type: :component do
  it "paints the brand chip with the brand token" do
    html = described_class.new(attribute: :brand_600, size: :small).call

    expect(html).to include("bg-brand-600")
    expect(html).not_to include("bg-secondary-600")
  end

  it "paints the secondary chip with the secondary token" do
    html = described_class.new(attribute: :brand_secondary_600, size: :small).call

    expect(html).to include("bg-secondary-600")
    expect(html).not_to include("bg-brand-600")
  end

  it "sizes the chip for a form readout or for a settings row" do
    small = described_class.new(attribute: :brand_600, size: :small).call
    large = described_class.new(attribute: :brand_600, size: :large).call

    expect(small).to include(described_class::SIZES.fetch(:small))
    expect(large).to include(described_class::SIZES.fetch(:large))
    expect(small).not_to include(described_class::SIZES.fetch(:large))
  end

  it "carries the data attributes its caller hands it" do
    html = described_class.new(attribute: :brand_600, size: :small, data: { "color-swatch-target": "chip" }).call

    expect(html).to include(%(data-color-swatch-target="chip"))
  end

  it "refuses a color the brand does not store" do
    expect { described_class.new(attribute: :accent_600, size: :small).call }.to raise_error(KeyError)
  end
end
