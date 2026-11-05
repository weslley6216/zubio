require "rails_helper"

RSpec.describe Components::Form::ColorSwatches, type: :component do
  it "names the group by the field alone" do
    html = described_class.new(label: "Destaque", hint: "Botão principal e o que está selecionado", attribute: :brand_600, selected: "#F0617A").call

    expect(html).to include(%(<fieldset aria-label="Destaque"))
  end

  it "stacks the label and the hint, instead of joining them on one line" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Fundo", hint: "A cor que veste a página", attribute: :brand_background, selected: "#16324A").call)

    legend = document.at_css("legend")
    expect(legend["class"].split).to include("flex-col", "w-full", "mb-2.5")
    expect(legend.at_xpath(".//*[normalize-space(text())='Fundo']")["class"]).to include("text-ink")
    expect(legend.at_xpath(".//*[normalize-space(text())='A cor que veste a página']")["class"]).to include("text-ink-muted")
  end

  it "arranges the suggestions and the plus in a wrapping row, not a fixed grid" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call)

    expect(document.at_css("[data-swatch-row]")["class"]).to include("flex-wrap")
    expect(document.to_html).to include(Components::Form::ColorSwatches::CUSTOM_SUMMARY)
  end

  it "shows the literal accent suggestions in the row, in order" do
    html = described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call

    expect(Nokogiri::HTML5.fragment(html).css("[data-swatch-row] [data-row-option] input[type=radio]").map { |radio| radio["value"] })
      .to eq(Branding::Palette::SUGGESTIONS.fetch(:brand_600))
  end

  it "shows the literal background suggestions in the row, in order" do
    html = described_class.new(label: "Fundo", hint: "hint", attribute: :brand_background, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_background).first).call

    expect(Nokogiri::HTML5.fragment(html).css("[data-swatch-row] [data-row-option] input[type=radio]").map { |radio| radio["value"] })
      .to eq(Branding::Palette::SUGGESTIONS.fetch(:brand_background))
  end

  it "marks no suggestion when nothing is stored, with the plus closed" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Fundo", hint: "hint", attribute: :brand_background, selected: nil).call)

    expect(document.css("[data-swatch-row] input[type=radio][checked]")).to be_empty
    expect(document.at_css("[data-swatch-row] [data-more-toggle]").key?("checked")).to be(false)
  end

  it "marks the stored suggestion in the row exactly once" do
    stored = Branding::Palette::SUGGESTIONS.fetch(:brand_600).last

    html = described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: stored).call

    expect(html).to include(%(value="#{stored}" checked))
    expect(html.scan(%(value="#{stored}" checked)).size).to eq(1)
  end

  it "paints an off-palette stored color through the tenant sheet, never through the palette sheet" do
    html = described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#123456").call

    expect(html).to include("bg-brand-600")
    expect(html).not_to include(%(data-swatch="#123456"))
  end

  it "opens the disclosure with the customize card selected when the stored color is off the palette" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#123456").call)

    expect(document.at_css("[data-more-toggle]").key?("checked")).to be(true)
    expect(document.at_css(%(input[value="custom"])).key?("checked")).to be(true)
    expect(document.at_css(%(input[name="branding[brand_600_custom]"]))["value"]).to eq("#123456")
  end

  it "keeps the plus unchecked when the stored color is a suggestion" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call)

    expect(document.at_css("[data-more-toggle]").key?("checked")).to be(false)
    expect(document.at_css(%(input[value="custom"]))["checked"]).to be_nil
  end

  it "reads the background color back through the background token, never the accent one" do
    html = described_class.new(label: "Fundo", hint: "hint", attribute: :brand_background, selected: "#123456", fallback: "#16324A").call

    expect(html).to include("bg-(--theme-bg)")
    expect(html).not_to include("bg-brand-600")
  end

  it "paints each swatch through the served palette sheet, never an inline style attribute" do
    html = described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::ACCENTS.first).call

    expect(html).to include(%(data-swatch="#{Branding::Palette::ACCENTS.first}"))
    expect(html).not_to include("style=")
  end

  it "offers no extra swatch and no disclosure grid, because the palette is curated" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call)

    expect(document.css("[data-swatch]").size).to eq(Branding::Palette::SUGGESTIONS.fetch(:brand_600).size)
    expect(document.to_html).to include(described_class::CUSTOMIZE_LABEL)
  end

  it "warns beside the code field, hidden until the controller flags it" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#4F46E5").call)

    message = document.at_css("[data-color-error]")
    expect(message.text).to include(described_class::INVALID_HEX_MESSAGE)
    expect(message.key?("hidden")).to be(true)
    expect(message["id"]).to eq("brand_600-color-error")
    expect(document.at_css("[data-code]").key?("aria-describedby")).to be(false)
  end

  it "shows the stored off-palette color beside the customize label" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: "#123456").call)

    expect(document.at_css(%(input[value="custom"])).parent.at_css(".bg-brand-600")).to be_present
  end

  it "shows no color beside the customize label when the stored color is a suggestion" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::ACCENTS.first).call)

    expect(document.at_css(%(input[value="custom"])).parent.text).to include(described_class::CUSTOMIZE_LABEL)
    expect(document.at_css(%(input[value="custom"])).parent.at_css(".bg-brand-600")).to be_nil
  end

  it "sizes each swatch to 44 by 44 with the inset hairline and the double selected ring" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call)

    swatch = document.at_css("[data-swatch]")
    expect(swatch["class"]).to include("h-11", "w-11", "rounded-xl")
    expect(swatch["class"]).to include("shadow-[inset_0_0_0_1px_rgba(14,26,36,0.12)]")
    expect(swatch["class"]).to include("peer-checked:shadow-[0_0_0_2px_#ffffff,0_0_0_4px_#0e1a24]")
  end

  it "draws the plus tile dashed, at the same 44 by 44 size as a swatch" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Destaque", hint: "hint", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call)

    plus = document.at_css("[data-more-toggle]").parent.at_css("span")
    expect(plus["class"]).to include("h-11", "w-11", "border-dashed", "text-[20px]")
    expect(plus.children.map(&:name)).to eq([ "text" ])
    expect(plus.text).to eq(described_class::CUSTOM_SUMMARY)
  end
end
