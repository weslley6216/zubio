require "rails_helper"

RSpec.describe Components::Form::ColorSwatches, type: :component do
  it "names the group by the field alone" do
    html = render_phlex(described_class.new(label: "Destaque", hint: "Botão principal e o que está selecionado", attribute: :brand_600, selected: "#F0617A"))

    expect(html).to include(%(<fieldset aria-label="Destaque"))
  end

  it "stacks the label and the hint, instead of joining them on one line" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Fundo", hint: "A cor que veste a página", attribute: :brand_background, selected: "#16324A")))

    legend = document.at_css("legend")
    expect(legend["class"].split).to include("flex-col", "w-full", "mb-2.5")
    expect(legend.at_xpath(".//*[normalize-space(text())='Fundo']")["class"]).to include("text-ink")
    expect(legend.at_xpath(".//*[normalize-space(text())='A cor que veste a página']")["class"]).to include("text-ink-muted")
  end

  it "arranges the suggestions and the plus in a wrapping row, not a fixed grid" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first)))

    expect(document.at_css("[data-swatch-row]")["class"]).to include("flex-wrap")
    expect(document.to_html).to include(Components::Form::ColorSwatches::CUSTOM_SUMMARY)
  end

  it "shows the literal accent suggestions in the row, in order" do
    html = render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first))

    expect(Nokogiri::HTML5.fragment(html).css("[data-swatch-row] [data-row-option] input[type=radio]").map { |radio| radio["value"] })
      .to eq(Branding::Palette::SUGGESTIONS.fetch(:brand_600))
  end

  it "shows the literal background suggestions in the row, in order" do
    html = render_phlex(described_class.new(label: "Fundo", hint: "hint", attribute: :brand_background, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_background).first))

    expect(Nokogiri::HTML5.fragment(html).css("[data-swatch-row] [data-row-option] input[type=radio]").map { |radio| radio["value"] })
      .to eq(Branding::Palette::SUGGESTIONS.fetch(:brand_background))
  end

  it "reajusts the accent row to a given background, keeping the same number of samples" do
    html = render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#F0617A", background: "#0000FF"))

    document = Nokogiri::HTML5.fragment(html)
    values = document.css("[data-swatch-row] [data-row-option] input[type=radio]").map { |radio| radio["value"] }

    expect(values.size).to eq(Branding::Palette::ACCENTS.size)
    expect(values).not_to include("#F0617A")
  end

  it "wraps the accent suggestions in the frame the background swaps, each remembering its palette slot" do
    html = render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#F0617A", background: "#0000FF"))

    radios = Nokogiri::HTML5.fragment(html).css("turbo-frame#accent-swatches input[type=radio]")

    expect(radios.map { |radio| radio["value"] }).to eq(Branding::Palette.accent_suggestions(background: "#0000FF"))
    expect(radios.map { |radio| radio["data-accent"] }).to eq(Branding::Palette::ACCENTS)
  end

  it "keeps the background suggestions out of the accent frame" do
    html = render_phlex(described_class.new(label: "Fundo", hint: "hint", attribute: :brand_background, selected: "#16324A"))

    expect(Nokogiri::HTML5.fragment(html).at_css("turbo-frame#accent-swatches")).to be_nil
  end

  it "colors the reajusted suggestions and the tones through the swatch sheet, since no inline style is allowed" do
    html = render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#F0617A", background: "#0000FF"))

    document = Nokogiri::HTML5.fragment(html)
    accent_sheet = document.at_css("turbo-frame#accent-swatches link[rel=stylesheet]")["href"]
    tones = document.css("turbo-frame#tones-brand_600 [data-tone]").map { |radio| radio["value"] }
    tones_sheet = document.at_css("turbo-frame#tones-brand_600 link[rel=stylesheet]")["href"]

    expect(accent_sheet).to eq("/swatches.css?colors=#{Branding::SwatchSheet.param(Branding::Palette.accent_suggestions(background: "#0000FF"))}")
    expect(tones_sheet).to eq("/swatches.css?colors=#{Branding::SwatchSheet.param(tones)}")
  end

  it "marks a saved reajusted suggestion in the row instead of reopening the customize card" do
    reajusted = Branding::Palette.accent_suggestions(background: "#0000FF").first

    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: reajusted, background: "#0000FF")))

    expect(reajusted).not_to eq(Branding::Palette::ACCENTS.first)
    expect(document.at_css(%(turbo-frame#accent-swatches input[value="#{reajusted}"])).key?("checked")).to be(true)
    expect(document.at_css(%(input[value="custom"])).key?("checked")).to be(false)
  end

  it "marks no suggestion when nothing is stored, with the plus closed" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Fundo", hint: "hint", attribute: :brand_background, selected: nil)))

    expect(document.css("[data-swatch-row] input[type=radio][checked]")).to be_empty
    expect(document.at_css("[data-swatch-row] [data-more-toggle]").key?("checked")).to be(false)
  end

  it "marks the stored suggestion in the row exactly once" do
    stored = Branding::Palette::SUGGESTIONS.fetch(:brand_600).last

    html = render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: stored))

    expect(html).to include(%(value="#{stored}" checked))
    expect(html.scan(%(value="#{stored}" checked)).size).to eq(1)
  end

  it "paints an off-palette stored color through the chosen-accent token, never through the palette sheet" do
    html = render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#123456"))

    expect(html).to include("bg-(--theme-accent)")
    expect(html).not_to include(%(data-swatch="#123456"))
  end

  it "opens the disclosure with the customize card selected when the stored color is off the palette" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#123456")))

    expect(document.at_css("[data-more-toggle]").key?("checked")).to be(true)
    expect(document.at_css(%(input[value="custom"])).key?("checked")).to be(true)
    expect(document.at_css(%(input[name="branding[brand_600_custom]"]))["value"]).to eq("#123456")
  end

  it "keeps the plus unchecked when the stored color is a suggestion" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first)))

    expect(document.at_css("[data-more-toggle]").key?("checked")).to be(false)
    expect(document.at_css(%(input[value="custom"]))["checked"]).to be_nil
  end

  it "reads the background color back through the background token, never the accent one" do
    html = render_phlex(described_class.new(label: "Fundo", hint: "hint", attribute: :brand_background, selected: "#123456", fallback: "#16324A"))

    expect(html).to include("bg-(--theme-bg)")
    expect(html).not_to include("bg-(--theme-accent)")
  end

  it "paints each swatch through the served palette sheet, never an inline style attribute" do
    html = render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::ACCENTS.first))

    expect(html).to include(%(data-swatch="#{Branding::Palette::ACCENTS.first}"))
    expect(html).not_to include("style=")
  end

  it "offers no extra swatch and no disclosure grid, because the palette is curated" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first)))

    expect(document.css("[data-swatch-row] [data-swatch]").size).to eq(Branding::Palette::SUGGESTIONS.fetch(:brand_600).size)
    expect(document.to_html).to include(described_class::CUSTOMIZE_LABEL)
  end

  it "warns beside the code field, hidden until the controller flags it" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#4F46E5")))

    message = document.at_css("[data-color-error]")
    expect(message.text).to include(described_class::INVALID_HEX_MESSAGE)
    expect(message.key?("hidden")).to be(true)
    expect(message["id"]).to eq("brand_600-color-error")
    expect(document.at_css("[data-code]").key?("aria-describedby")).to be(false)
  end

  it "shows the stored off-palette color beside the customize label" do
    html = render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#123456"))

    expect(html).to include(described_class::CUSTOMIZE_LABEL)
    expect(html).to include("bg-(--theme-accent)")
  end

  it "shows no chip beside the customize label when the stored color is a suggestion" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::ACCENTS.first)))

    expect(document.at_css(%(input[value="custom"])).parent.text).to include(described_class::CUSTOMIZE_LABEL)
    expect(document.at_css(%(input[value="custom"])).parent.at_css("[data-swatch]")).to be_nil
  end

  it "sizes each swatch to 44 by 44 with the inset hairline and the double selected ring" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first)))

    swatch = document.at_css("[data-swatch]")
    expect(swatch["class"]).to include("h-11", "w-11", "rounded-xl")
    expect(swatch["class"]).to include("shadow-[inset_0_0_0_1px_rgba(14,26,36,0.12)]")
    expect(swatch["class"]).to include("peer-checked:shadow-[0_0_0_2px_#ffffff,0_0_0_4px_#0e1a24]")
  end

  it "draws the plus tile dashed, at the same 44 by 44 size as a swatch" do
    document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first)))

    plus = document.at_css("[data-more-toggle]").parent.at_css("span")
    expect(plus["class"]).to include("h-11", "w-11", "border-dashed", "text-[20px]")
    expect(plus.children.map(&:name)).to eq([ "text" ])
    expect(plus.text).to eq(described_class::CUSTOM_SUMMARY)
  end

  describe "the native color picker is replaced by a hue bar and a tones frame (AC1)" do
    it "renders no native color input" do
      html = render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#4F46E5"))

      expect(html).not_to include(%(type="color"))
    end

    it "renders a hue range from 0 to 359" do
      document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#4F46E5")))

      range = document.at_css(%(input[type="range"]))
      expect(range["min"]).to eq("0")
      expect(range["max"]).to eq("359")
    end

    it "renders a tones turbo frame scoped to the attribute" do
      document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#4F46E5")))

      expect(document.at_css("turbo-frame#tones-brand_600")).to be_present
    end

    it "renders without raising when the stored selection is not a well-formed hex" do
      expect { render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "AZUL")) }.not_to raise_error
    end

    it "keeps the custom hex field alongside the hue bar" do
      document = Nokogiri::HTML5.fragment(render_phlex(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#4F46E5")))

      expect(document.at_css(%(input[name="branding[brand_600_custom]"]))).to be_present
    end
  end
end
