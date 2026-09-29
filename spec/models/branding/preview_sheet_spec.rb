require "rails_helper"

RSpec.describe Branding::PreviewSheet do
  describe "#stylesheet" do
    it "carries a brand preview ramp addressable by the hex" do
      sheet = described_class.new(brand: "#2C6CB0", secondary: nil).stylesheet

      expect(sheet).to include(%([data-preview-brand="#2C6CB0"]{))
      expect(sheet).to include("--brand-600:#2C6CB0;")
    end

    it "derives the on-brand token from the contrast foreground the scale chooses" do
      sheet = described_class.new(brand: "#2C6CB0", secondary: nil).stylesheet

      expect(sheet).to include("--on-brand:#{Branding::ColorScale.new("#2C6CB0").foreground};")
    end

    it "carries a support preview ramp addressable by the hex" do
      sheet = described_class.new(brand: nil, secondary: "#E8493C").stylesheet

      expect(sheet).to include(%([data-preview-secondary="#E8493C"]{))
      expect(sheet).to include("--secondary-600:#E8493C;")
    end

    it "serves only the role that was given, never the absent one" do
      brand_only = described_class.new(brand: "#2C6CB0", secondary: nil).stylesheet
      secondary_only = described_class.new(brand: nil, secondary: "#E8493C").stylesheet

      expect(brand_only).not_to include("data-preview-secondary")
      expect(secondary_only).not_to include("data-preview-brand")
    end

    it "carries both ramps when both hexes are given" do
      sheet = described_class.new(brand: "#2C6CB0", secondary: "#E8493C").stylesheet

      expect(sheet).to include(%([data-preview-brand="#2C6CB0"]{))
      expect(sheet).to include(%([data-preview-secondary="#E8493C"]{))
    end

    it "is empty when neither hex is given" do
      expect(described_class.new(brand: nil, secondary: nil).stylesheet).to eq("")
    end
  end
end
