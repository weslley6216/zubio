require "rails_helper"

RSpec.describe Branding::PreviewSheet do
  describe "#stylesheet" do
    it "carries the background-derived tokens addressable by the hex" do
      sheet = described_class.new(bg: "#16324A", accent: nil).stylesheet

      expect(sheet).to include(%([data-preview-bg="#16324A"]{))
      expect(sheet).to include("--theme-bg:#16324A;")
    end

    it "carries the accent tokens addressable by the hex" do
      sheet = described_class.new(bg: nil, accent: "#F0617A").stylesheet

      expect(sheet).to include(%([data-preview-accent="#F0617A"]{))
      expect(sheet).to include("--theme-accent:#F0617A;")
    end

    it "serves only the role that was given, never the absent one" do
      bg_only = described_class.new(bg: "#16324A", accent: nil).stylesheet
      accent_only = described_class.new(bg: nil, accent: "#F0617A").stylesheet

      expect(bg_only).not_to include("data-preview-accent")
      expect(accent_only).not_to include("data-preview-bg")
    end

    it "carries both rules when both hexes are given" do
      sheet = described_class.new(bg: "#16324A", accent: "#F0617A").stylesheet

      expect(sheet).to include(%([data-preview-bg="#16324A"]{))
      expect(sheet).to include(%([data-preview-accent="#F0617A"]{))
    end

    it "is empty when neither hex is given" do
      expect(described_class.new(bg: nil, accent: nil).stylesheet).to eq("")
    end
  end
end
