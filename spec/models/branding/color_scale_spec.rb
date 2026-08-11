require "rails_helper"

RSpec.describe Branding::ColorScale do
  describe "#initialize" do
    it "accepts a well-formed 6-digit hex color" do
      color_scale = described_class.new("#4F46E5")

      expect(color_scale.hex).to eq("#4F46E5")
    end

    it "raises for a value that is not a 6-digit hex color" do
      expect { described_class.new("#4F46E5; } body { display: none } .x {") }
        .to raise_error(ArgumentError)
    end

    it "raises for a 3-digit hex shorthand" do
      expect { described_class.new("#fff") }.to raise_error(ArgumentError)
    end
  end

  describe "#contrast_against_white" do
    it "is 21.0 for pure black" do
      expect(described_class.new("#000000").contrast_against_white).to eq(21.0)
    end

    it "is 1.0 for pure white" do
      expect(described_class.new("#ffffff").contrast_against_white).to eq(1.0)
    end
  end

  describe "#foreground" do
    it "is white on a black background" do
      expect(described_class.new("#000000").foreground).to eq(described_class::WHITE)
    end

    it "is the dark neutral on a white background" do
      expect(described_class.new("#ffffff").foreground).to eq(described_class::DARK_NEUTRAL)
    end
  end

  describe "#tokens" do
    it "returns the exact input at step 600 and a lighter-to-darker gray ramp for an achromatic input" do
      tokens = described_class.new("#000000").tokens

      expect(tokens).to eq(
        50 => "#f7f7f7", 100 => "#f0f0f0", 200 => "#dbdbdb", 300 => "#c2c2c2",
        400 => "#a8a8a8", 500 => "#8f8f8f", 600 => "#000000",
        700 => "#6b6b6b", 800 => "#525252", 900 => "#383838"
      )
    end

    it "returns a well-formed 10-step scale across the hue spectrum, always echoing step 600 verbatim" do
      hues = %w[#E11D48 #16A34A #2563EB #4F46E5 #CA8A04 #0D9488 #DB2777 #84CC16]

      hues.each do |hex|
        tokens = described_class.new(hex).tokens

        expect(tokens.keys).to eq([50, 100, 200, 300, 400, 500, 600, 700, 800, 900])
        expect(tokens[600]).to eq(hex)
        expect(tokens.values).to all(match(described_class::HEX))
      end
    end
  end
end
