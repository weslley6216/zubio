require "rails_helper"

RSpec.describe Branding::Palette do
  describe ".swatches" do
    it "offers two depths for each family" do
      expect(described_class.swatches.size).to eq(described_class::FAMILIES.size * 2)
    end

    it "offers only colors the brand color validation accepts" do
      rejected = described_class.swatches.reject { |hex| build(:branding, brand_600: hex).valid? }

      expect(rejected).to be_empty
    end

    it "reaches beyond what a fixed white foreground would allow" do
      only_on_dark = described_class.swatches.select do |hex|
        Branding::ColorScale.new(hex).foreground == Branding::ColorScale::DARK_NEUTRAL
      end

      expect(only_on_dark).not_to be_empty
    end

    it "never repeats a color" do
      expect(described_class.swatches.uniq).to eq(described_class.swatches)
    end

    it "keeps every derived depth darker than the family it came from" do
      lightened = described_class::FAMILIES.select do |hex|
        family = Branding::ColorScale.new(hex)

        Branding::ColorScale.new(family.deepened_hex).luminance >= family.luminance
      end

      expect(lightened).to be_empty
    end
  end

  describe ".stylesheet" do
    it "carries one background rule per swatch, addressable by the swatch value" do
      expect(described_class.stylesheet).to include(%([data-swatch="#{described_class::FAMILIES.first}"]))
      expect(described_class.stylesheet.scan("background:").size).to eq(described_class.swatches.size)
    end
  end

  describe ".stylesheet_digest" do
    it "is short enough to travel in a URL" do
      expect(described_class.stylesheet_digest.length).to eq(Branding::DIGEST_LENGTH)
    end
  end
end
