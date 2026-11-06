require "rails_helper"

RSpec.describe Branding::Palette do
  describe ".swatches" do
    it "unions the backgrounds and the accents, with no repeats" do
      expect(described_class.swatches).to eq((described_class::BACKGROUNDS + described_class::ACCENTS).uniq)
      expect(described_class.swatches.size).to eq(10)
    end
  end

  describe "SUGGESTIONS" do
    it "opens the background suggestions with the canvas pairs, in product-decided order" do
      expect(described_class::SUGGESTIONS.fetch(:brand_background).first(3)).to eq(%w[#16324A #F6EEF2 #1F4D3A])
    end

    it "opens the accent suggestions with the canvas pairs, in product-decided order" do
      expect(described_class::SUGGESTIONS.fetch(:brand_600).first(3)).to eq(%w[#F0617A #8E4B6B #F2B33D])
    end
  end

  describe "STARTING" do
    it "is a background and accent pair drawn from the suggestions" do
      expect(described_class::STARTING.fetch(:brand_background)).to be_in(described_class::BACKGROUNDS)
      expect(described_class::STARTING.fetch(:brand_600)).to be_in(described_class::ACCENTS)
    end

    it "passes the full branding validation, including the stands-out rule" do
      branding = build(:branding, brand_background: described_class::STARTING.fetch(:brand_background), brand_600: described_class::STARTING.fetch(:brand_600))

      expect(branding).to be_valid
    end
  end

  describe "canvas pairs" do
    it "accepts the Zé pair" do
      branding = build(:branding, brand_background: "#16324A", brand_600: "#F0617A")

      expect(branding).to be_valid
    end

    it "accepts the Mary pair" do
      branding = build(:branding, brand_background: "#F6EEF2", brand_600: "#8E4B6B")

      expect(branding).to be_valid
    end

    it "accepts the Pet pair" do
      branding = build(:branding, brand_background: "#1F4D3A", brand_600: "#F2B33D")

      expect(branding).to be_valid
    end
  end

  describe ".extras" do
    it "offers nothing beyond the curated suggestions" do
      expect(described_class.extras(:brand_background)).to eq([])
      expect(described_class.extras(:brand_600)).to eq([])
    end
  end

  describe ".stylesheet" do
    it "carries one background rule per swatch, addressable by the swatch value" do
      expect(described_class.stylesheet).to include(%([data-swatch="#{described_class::BACKGROUNDS.first}"]))
      expect(described_class.stylesheet.scan("background:").size).to eq(described_class.swatches.size)
    end

    it "carries a background preview rule for each literal background" do
      hex = described_class::BACKGROUNDS.first

      expect(described_class.stylesheet).to include(%([data-preview-bg="#{hex}"]{))
      expect(described_class.stylesheet).to include("--theme-bg:#{hex};")
    end

    it "carries an accent preview rule for each literal accent" do
      hex = described_class::ACCENTS.first

      expect(described_class.stylesheet).to include(%([data-preview-accent="#{hex}"]{))
      expect(described_class.stylesheet).to include("--theme-accent:#{hex};")
    end

    it "carries a none rule for the background, falling back to the neutral surface" do
      expect(described_class.stylesheet).to include(%([data-preview-bg="none"]{))
    end

    it "never carries an accent none rule, because the accent has no empty state" do
      expect(described_class.stylesheet).not_to include(%([data-preview-accent="none"]))
    end
  end

  describe ".stylesheet_digest" do
    it "is short enough to travel in a URL" do
      expect(described_class.stylesheet_digest.length).to eq(StylesheetProducer::DIGEST_LENGTH)
    end
  end
end
