require "rails_helper"

RSpec.describe Branding::Theme do
  describe "#tokens" do
    it "resolves the ADR table for a dark blue background with a light pink accent" do
      theme = described_class.new(background: "#16324A", accent: "#F0617A")

      expect(theme.tokens).to eq(
        "bg" => "#16324A",
        "on-bg" => "#ffffff",
        "on-bg-muted" => "#ccd2d7",
        "bg-tint" => "#374f63",
        "ghost" => "#738492",
        "danger-on-bg" => "#ffb4be",
        "danger-line-on-bg" => "#8b7384",
        "card" => "#e7f0f8",
        "on-card" => "#0e1a24",
        "on-card-muted" => "#3e4953",
        "card-line" => "#cdd6df",
        "card-chip" => "#f7fafd",
        "field-line" => "#7b858e",
        "focus" => "#16324A",
        "danger-on-card" => "#b42318",
        "accent" => "#F0617A",
        "on-accent" => "#0e1a24",
        "selected-ring" => "#0e1a24"
      )
    end

    it "resolves the ADR table for a dark green background with a light yellow accent" do
      theme = described_class.new(background: "#1F4D3A", accent: "#F2B33D")

      expect(theme.tokens).to eq(
        "bg" => "#1F4D3A",
        "on-bg" => "#ffffff",
        "on-bg-muted" => "#ced8d4",
        "bg-tint" => "#3e6656",
        "ghost" => "#849d93",
        "danger-on-bg" => "#ffb4be",
        "danger-line-on-bg" => "#8f817c",
        "card" => "#e9f6f1",
        "on-card" => "#0e1a24",
        "on-card-muted" => "#3e4a51",
        "card-line" => "#cfdcd8",
        "card-chip" => "#f7fcfa",
        "field-line" => "#7c888b",
        "focus" => "#1F4D3A",
        "danger-on-card" => "#b42318",
        "accent" => "#F2B33D",
        "on-accent" => "#0e1a24",
        "selected-ring" => "#0e1a24"
      )
    end

    it "resolves the ADR table for a light pink background with a dark purple accent" do
      theme = described_class.new(background: "#F6EEF2", accent: "#8E4B6B")

      expect(theme.tokens).to eq(
        "bg" => "#F6EEF2",
        "on-bg" => "#0e1a24",
        "on-bg-muted" => "#414951",
        "bg-tint" => "#d6d0d5",
        "ghost" => "#82848b",
        "danger-on-bg" => "#b42318",
        "danger-line-on-bg" => "#d58985",
        "card" => "#ffffff",
        "on-card" => "#0e1a24",
        "on-card-muted" => "#434c54",
        "card-line" => "#e2e4e5",
        "card-chip" => "#ffffff",
        "field-line" => "#878d92",
        "focus" => "#8E4B6B",
        "danger-on-card" => "#b42318",
        "accent" => "#8E4B6B",
        "on-accent" => "#ffffff"
      )
    end

    it "resolves the ADR table with no background" do
      theme = described_class.new(background: nil, accent: "#4F46E5")

      expect(theme.tokens).to eq(
        "bg" => "#f8fafb",
        "on-bg" => "#0e1a24",
        "on-bg-muted" => "#414b53",
        "bg-tint" => "#d7dbdd",
        "ghost" => "#838a90",
        "danger-on-bg" => "#b42318",
        "danger-line-on-bg" => "#d68f8a",
        "card" => "#ffffff",
        "on-card" => "#0e1a24",
        "on-card-muted" => "#434c54",
        "card-line" => "#e2e4e5",
        "card-chip" => "#ffffff",
        "field-line" => "#878d92",
        "focus" => "#4F46E5",
        "danger-on-card" => "#b42318",
        "accent" => "#4F46E5",
        "on-accent" => "#ffffff"
      )
    end

    it "cuts the card of a dark background from step 100 of its own ramp" do
      dark_blue = described_class.new(background: "#16324A", accent: "#F0617A")
      dark_green = described_class.new(background: "#1F4D3A", accent: "#F2B33D")

      expect(dark_blue.tokens["card"]).to eq(Branding::ColorScale.new("#16324A").tokens[100])
      expect(dark_green.tokens["card"]).to eq(Branding::ColorScale.new("#1F4D3A").tokens[100])
    end

    it "falls back to the neutral surface-2 when no background is chosen" do
      theme = described_class.new(background: nil, accent: "#4F46E5")

      expect(theme.background).to eq(Branding::NEUTRALS.fetch(:light).fetch("surface-2"))
      expect(theme.tokens["card"]).to eq("#ffffff")
    end

    it "rings the selected item in the card text when the accent fades on the card" do
      theme = described_class.new(background: "#1F4D3A", accent: "#F2B33D")

      expect(theme.tokens["selected-ring"]).to eq(theme.tokens["on-card"])
    end

    it "leaves the ring out when the accent already stands out on the card" do
      theme = described_class.new(background: "#F6EEF2", accent: "#8E4B6B")

      expect(theme.tokens).not_to have_key("selected-ring")
    end

    it "writes every dark text in the app ink" do
      examples = [
        described_class.new(background: "#16324A", accent: "#F0617A"),
        described_class.new(background: "#1F4D3A", accent: "#F2B33D"),
        described_class.new(background: "#F6EEF2", accent: "#8E4B6B"),
        described_class.new(background: nil, accent: "#4F46E5")
      ]

      examples.each do |theme|
        dark_texts = theme.tokens.values_at("on-bg", "on-card", "on-accent").reject { |hex| hex == "#ffffff" }

        expect(dark_texts).to all(eq("#0e1a24"))
        expect(theme.tokens.values).not_to include("#111827")
      end
    end

    it "climbs the ghost outline past the canvas 35% until it reaches 3:1" do
      theme = described_class.new(background: "#16324A", accent: "#F0617A")

      expect(theme.tokens["ghost"]).to eq("#738492")
      early_candidate = Branding::ColorScale.new("#ffffff").mix("#16324A", 35)
      expect(Branding::ColorScale.new(early_candidate).contrast_against(Branding::ColorScale.new("#16324A"))).to be < 3.0
    end

    it "focuses the card on the accent when the background fades on it" do
      theme = described_class.new(background: "#F6EEF2", accent: "#8E4B6B")

      expect(theme.tokens["focus"]).to eq("#8E4B6B")
      field_line = Branding::ColorScale.new(theme.tokens["field-line"])
      card = Branding::ColorScale.new(theme.tokens["card"])
      expect(field_line.contrast_against(card)).to be >= 3.0
    end

    it "falls back to the role's own text when no step of the climb reaches the minimum" do
      theme = described_class.new(background: "#767676", accent: "#4F46E5")

      expect(theme.tokens["on-bg"]).to eq("#ffffff")
      expect(theme.tokens["on-bg-muted"]).to eq("#ffffff")
    end

    it "solves every token to a solid six-digit hex" do
      examples = [
        described_class.new(background: "#16324A", accent: "#F0617A"),
        described_class.new(background: "#1F4D3A", accent: "#F2B33D"),
        described_class.new(background: "#F6EEF2", accent: "#8E4B6B"),
        described_class.new(background: nil, accent: "#4F46E5")
      ]

      examples.each do |theme|
        expect(theme.tokens.values).to all(match(/\A#\h{6}\z/))
      end
    end

    it "keeps every text and boundary token at its minimum for every palette swatch as background" do
      failures = Branding::Palette.swatches.flat_map do |swatch|
        theme = described_class.new(background: swatch, accent: "#4F46E5")
        tokens = theme.tokens
        bg = Branding::ColorScale.new(tokens["bg"])
        card = Branding::ColorScale.new(tokens["card"])

        text_on_bg = %w[on-bg on-bg-muted danger-on-bg].reject do |name|
          Branding::ColorScale.new(tokens[name]).contrast_against(bg) >= Branding::ColorScale::MIN_CONTRAST
        end
        boundary_on_bg = %w[ghost].reject do |name|
          Branding::ColorScale.new(tokens[name]).contrast_against(bg) >= Branding::ColorScale::MIN_NON_TEXT_CONTRAST
        end
        text_on_card = %w[on-card on-card-muted danger-on-card].reject do |name|
          Branding::ColorScale.new(tokens[name]).contrast_against(card) >= Branding::ColorScale::MIN_CONTRAST
        end
        boundary_on_card = %w[field-line focus].reject do |name|
          Branding::ColorScale.new(tokens[name]).contrast_against(card) >= Branding::ColorScale::MIN_NON_TEXT_CONTRAST
        end

        (text_on_bg + boundary_on_bg + text_on_card + boundary_on_card).map { |name| "#{swatch}: #{name}" }
      end

      expect(Branding::Palette.swatches.size).to eq(24)
      expect(failures).to be_empty
    end

    it "reads the accent's own text at 4.5:1 for every swatch" do
      failures = Branding::Palette.swatches.flat_map do |swatch|
        theme = described_class.new(background: nil, accent: swatch)
        accent = Branding::ColorScale.new(theme.tokens["accent"])
        on_accent = Branding::ColorScale.new(theme.tokens["on-accent"])

        on_accent.contrast_against(accent) >= Branding::ColorScale::MIN_CONTRAST ? [] : [ swatch ]
      end

      expect(failures).to be_empty
    end
  end

  describe "#accent_stands_out?" do
    it "refuses an accent lost on the background" do
      theme = described_class.new(background: "#16324A", accent: "#1E3A55")

      expect(theme.accent_stands_out?).to eq(false)
    end

    it "accepts an accent that stands out on the background" do
      theme = described_class.new(background: "#16324A", accent: "#F0617A")

      expect(theme.accent_stands_out?).to eq(true)
    end

    it "measures a light accent against the neutral when there is no background" do
      lost = described_class.new(background: nil, accent: "#EAB308")
      standing_out = described_class.new(background: nil, accent: "#4F46E5")

      expect(lost.accent_stands_out?).to eq(false)
      expect(standing_out.accent_stands_out?).to eq(true)
    end
  end

  describe "#css_variables" do
    it "serializes each token as a theme custom property, in order" do
      theme = described_class.new(background: "#16324A", accent: "#F0617A")

      expect(theme.css_variables).to start_with("--theme-bg:#16324A;--theme-on-bg:#ffffff;")
      expect(theme.css_variables).to end_with("--theme-selected-ring:#0e1a24;")
    end
  end
end
