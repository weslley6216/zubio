require "rails_helper"

RSpec.describe Components::Form::ColorSwatches, type: :component do
  it "names the group by the field alone" do
    html = described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#4F46E5").call

    expect(html).to include(%(<fieldset aria-label="Cor principal"))
  end

  it "carries the label, the hint and an optional tag when given one" do
    html = described_class.new(
      label: "Cor de apoio", hint: "Detalhes e destaques", attribute: :brand_secondary_600, selected: nil, fallback: "#4F46E5", tag: "Opcional"
    ).call

    expect(html).to include("Cor de apoio")
    expect(html).to include("Detalhes e destaques")
    expect(html).to include("Opcional")
  end

  it "carries no tag when not given one" do
    html = described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#4F46E5").call

    expect(html).to include("Cor principal")
    expect(html).not_to include("Opcional")
  end

  it "arranges the five suggestions and the plus in a grid of six columns" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call)

    expect(document.at_css("[data-swatch-row]")["class"]).to include("grid-cols-6")
    expect(document.to_html).to include(Components::Form::ColorSwatches::CUSTOM_SUMMARY)
  end

  it "shows the five brand suggestions in the row" do
    html = described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call

    expect(Nokogiri::HTML5.fragment(html).css("[data-swatch-row] [data-row-option] input[type=radio]").map { |radio| radio["value"] })
      .to eq(Branding::Palette::SUGGESTIONS.fetch(:brand_600))
  end

  it "opens the support suggestions with a none option carrying the empty value" do
    html = described_class.new(
      label: "Cor de apoio", hint: "Detalhes e destaques", attribute: :brand_secondary_600, selected: nil, fallback: "#4F46E5", tag: "Opcional"
    ).call

    expect(html).to include("Sem")
    expect(html).to include(%(value="" checked))
  end

  it "marks the stored suggestion in the row exactly once" do
    stored = Branding::Palette::SUGGESTIONS.fetch(:brand_600).last

    html = described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: stored).call

    expect(html).to include(%(value="#{stored}" checked))
    expect(html.scan(%(value="#{stored}" checked)).size).to eq(1)
  end

  it "keeps the row at the five suggestions plus the plus, never the off-palette color" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#7E22CE").call)

    expect(document.css("[data-swatch-row] [data-row-option] input[type=radio]").map { |radio| radio["value"] })
      .to eq(Branding::Palette::SUGGESTIONS.fetch(:brand_600))
    expect(document.at_css("[data-swatch-row] [data-more-toggle]")).to be_present
  end

  it "paints an off-palette stored color through the tenant sheet, never through the palette sheet" do
    html = described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#123456").call

    expect(html).to include("bg-brand-600")
    expect(html).not_to include(%(data-swatch="#123456"))
  end

  it "opens the disclosure with the customize card selected when the stored color is off the palette" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#123456").call)

    expect(document.at_css("details")).to be_nil
    expect(document.at_css("[data-more-toggle]").key?("checked")).to be(true)
    expect(document.at_css(%(input[value="custom"])).key?("checked")).to be(true)
    expect(document.at_css(%(input[name="branding[brand_600_custom]"]))["value"]).to eq("#123456")
  end

  it "keeps the plus unchecked when the stored color is a suggestion" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call)

    expect(document.at_css(%(input[value="custom"]))["checked"]).to be_nil
  end

  it "reads the support color back through the support token, never the brand one" do
    html = described_class.new(
      label: "Cor de apoio", hint: "Detalhes e destaques", attribute: :brand_secondary_600, selected: "#123456", fallback: "#4F46E5", tag: "Opcional"
    ).call

    expect(html).to include("bg-secondary-600")
    expect(html).not_to include("bg-brand-600")
  end

  it "paints each swatch through the served palette sheet, never an inline style attribute" do
    html = described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: Branding::Palette.swatches.first).call

    expect(html).to include(%(data-swatch="#{Branding::Palette.swatches.first}"))
    expect(html).not_to include("style=")
  end

  it "reveals the rest of the palette and a customize card behind the plus" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: Branding::Palette::SUGGESTIONS.fetch(:brand_600).first).call)

    expect(document.css("[data-swatch]").map { |swatch| swatch["data-swatch"] }).to include(*Branding::Palette.extras(:brand_600))
    expect(document.to_html).to include(described_class::CUSTOMIZE_LABEL)
  end

  it "warns beside the code field, hidden until the controller flags it" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#4F46E5").call)

    message = document.at_css("[data-color-error]")
    expect(message.text).to include(described_class::INVALID_HEX_MESSAGE)
    expect(message.key?("hidden")).to be(true)
    expect(message["id"]).to eq("brand_600-color-error")
    expect(document.at_css("[data-code]").key?("aria-describedby")).to be(false)
  end

  it "spreads the customize card over two cells so its label fits" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#4F46E5").call)

    card = document.at_css(%(input[value="custom"])).parent
    expect(card["class"]).to include("col-span-2")
    expect(card.text).to include(described_class::CUSTOMIZE_LABEL)
  end

  it "shows the stored off-palette color beside the customize label" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#123456").call)

    expect(document.at_css(%(input[value="custom"])).parent.at_css(".bg-brand-600")).to be_present
  end

  it "shows no color beside the customize label when the stored color is a suggestion" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#4F46E5").call)

    expect(document.at_css(%(input[value="custom"])).parent.text).to include(described_class::CUSTOMIZE_LABEL)
    expect(document.at_css(%(input[value="custom"])).parent.at_css(".bg-brand-600")).to be_nil
  end

  it "renders the optional tag as a rounded neutral badge, not loose text" do
    document = Nokogiri::HTML5.fragment(described_class.new(
      label: "Cor de apoio", hint: "Detalhes e destaques", attribute: :brand_secondary_600, selected: nil, fallback: "#4F46E5", tag: "Opcional"
    ).call)

    tag = document.css("legend span").last
    expect(tag.text).to eq("Opcional")
    expect(tag["class"]).to include("rounded-full")
    expect(tag["class"]).to include("bg-surface-3")
    expect(tag["class"]).to include("text-[10px]")
  end

  it "styles the group legend with the shared section-label token" do
    document = Nokogiri::HTML5.fragment(described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: "#4F46E5").call)

    expect(document.at_css("legend")["class"]).to include(Components::Form::Styles::SECTION_LABEL)
  end
end
