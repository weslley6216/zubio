require "rails_helper"

RSpec.describe Branding::Tones do
  describe "#options" do
    backgrounds = %w[#16324A #F6EEF2 #0000FF]
    hues = (0...360).step(30).to_a + [ described_class::NEUTRAL ]

    backgrounds.each do |background|
      hues.each do |hue|
        it "offers at least one valid accent for hue #{hue} over #{background}" do
          tones = described_class.new(role: :brand_600, background: background)

          expect(tones.options(hue)).not_to be_empty
        end
      end
    end

    it "every option passes 4.5:1 against its own foreground and 3:1 against the background" do
      tones = described_class.new(role: :brand_600, background: "#16324A")

      tones.options(210).each do |hex|
        scale = Branding::ColorScale.new(hex)

        expect(scale.contrast_against_foreground).to be >= Branding::ColorScale::MIN_CONTRAST
        expect(scale.contrast_against(Branding::ColorScale.new("#16324A"))).to be >= Branding::ColorScale::MIN_NON_TEXT_CONTRAST
      end
    end

    it "excludes the red that fails over a blue background, but keeps a valid red" do
      tones = described_class.new(role: :brand_600, background: "#0000FF")

      expect(tones.options(0)).not_to include("#FF0000")
      expect(tones.options(0)).not_to be_empty
    end
  end

  describe "#nearest_valid" do
    it "returns a valid tone of the same hue, different from the invalid hex" do
      tones = described_class.new(role: :brand_600, background: "#0000FF")

      result = tones.nearest_valid("#FF0000")

      expect(tones.valid?(result)).to be true
      expect(Branding::ColorScale.new(result).hue).to be_within(1).of(Branding::ColorScale.new("#FF0000").hue)
      expect(result).not_to eq("#FF0000")
    end

    it "returns the exact hex unchanged when it is already valid" do
      tones = described_class.new(role: :brand_600, background: "#16324A")

      expect(tones.nearest_valid("#F0617A")).to eq("#F0617A")
    end
  end

  describe "role brand_background" do
    it "accepts a light tone that reads with text" do
      tones = described_class.new(role: :brand_background)

      expect(tones.valid?("#F6EEF2")).to be true
    end

    it "rejects a mid-luminance tone that fails the text contrast, with no stands-out rule involved" do
      tones = described_class.new(role: :brand_background)

      expect(tones.valid?("#808080")).to be false
    end
  end

  describe "a nil background" do
    it "falls back to the neutral surface-2, matching an empty string background" do
      with_nil = described_class.new(role: :brand_600, background: nil)
      with_blank = described_class.new(role: :brand_600, background: "")

      expect(with_nil.valid?("#F0617A")).to eq(with_blank.valid?("#F0617A"))
    end
  end
end
