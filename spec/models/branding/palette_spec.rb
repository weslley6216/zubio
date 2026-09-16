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

  describe "SUGGESTIONS" do
    it "suggests five brand colors, all drawn from the families" do
      expect(described_class::SUGGESTIONS.fetch(:brand_600).size).to eq(5)
      expect(described_class::SUGGESTIONS.fetch(:brand_600)).to all(be_in(described_class::FAMILIES))
    end

    it "opens the support suggestions with the none option and draws the rest from the families" do
      support = described_class::SUGGESTIONS.fetch(:brand_secondary_600)

      expect(support.first).to eq("")
      expect(support.drop(1)).to all(be_in(described_class::FAMILIES))
    end
  end

  describe ".stylesheet" do
    it "carries one background rule per swatch, addressable by the swatch value" do
      expect(described_class.stylesheet).to include(%([data-swatch="#{described_class::FAMILIES.first}"]))
      expect(described_class.stylesheet.scan("background:").size).to eq(described_class.swatches.size)
    end

    it "carries a brand and a support preview ramp for each swatch" do
      hex = described_class::FAMILIES.first

      expect(described_class.stylesheet).to include(%([data-preview-brand="#{hex}"]{))
      expect(described_class.stylesheet).to include(%([data-preview-secondary="#{hex}"]{))
      expect(described_class.stylesheet).to include("--brand-600:#{hex};")
    end

    it "maps every support token to its brand counterpart under the none rule" do
      rule = described_class.stylesheet[/\[data-preview-secondary="none"\]\{([^}]*)\}/, 1]

      expect(rule).to include("--secondary-600:var(--brand-600);")
      expect(rule).to include("--secondary-mark-light:var(--brand-mark-light);")
    end
  end

  describe ".stylesheet_digest" do
    it "is short enough to travel in a URL" do
      expect(described_class.stylesheet_digest.length).to eq(StylesheetProducer::DIGEST_LENGTH)
    end
  end
end
