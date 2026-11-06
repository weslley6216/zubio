require "rails_helper"

RSpec.describe Branding::SwatchSheet do
  describe ".param" do
    it "joins the hexes without the hash, in capitals" do
      expect(described_class.param(%w[#1e3a55 #F0617A])).to eq("1E3A55-F0617A")
    end
  end

  describe "#stylesheet" do
    it "paints each swatch addressable by its hex" do
      sheet = described_class.new("1E3A55-F0617A").stylesheet

      expect(sheet).to eq(%([data-swatch="#1E3A55"]{background:#1E3A55;color:#1E3A55}[data-swatch="#F0617A"]{background:#F0617A;color:#F0617A}))
    end

    it "drops any entry that is not a color, never echoing it" do
      sheet = described_class.new("1E3A55-fff;}body{background:red-ZZZ123").stylesheet

      expect(sheet).to eq(%([data-swatch="#1E3A55"]{background:#1E3A55;color:#1E3A55}))
    end

    it "stops at the most swatches a row can hold" do
      colors = Array.new(described_class::MAX_COLORS + 1) { |index| format("%06X", index) }.join("-")

      sheet = described_class.new(colors).stylesheet

      expect(sheet.scan("[data-swatch=").size).to eq(described_class::MAX_COLORS)
    end

    it "is empty when nothing is given" do
      expect(described_class.new(nil).stylesheet).to eq("")
    end
  end
end
