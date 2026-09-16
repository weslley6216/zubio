require "rails_helper"

RSpec.describe Components::Form::ColorSwatches, type: :component do
  def brand_swatches(selected)
    described_class.new(label: "Cor principal", hint: "Botões e cabeçalho", attribute: :brand_600, selected: selected).call
  end

  def secondary_swatches(selected)
    described_class.new(label: "Cor de apoio", hint: "Detalhes e destaques", attribute: :brand_secondary_600,
      selected: selected, fallback: "#4F46E5", tag: "Opcional").call
  end

  it "names the group by the field alone" do
    expect(brand_swatches("#4F46E5")).to include(%(<fieldset aria-label="Cor principal"))
  end

  it "carries the label, the hint and an optional tag when given one" do
    expect(secondary_swatches(nil)).to include("Cor de apoio")
    expect(secondary_swatches(nil)).to include("Detalhes e destaques")
    expect(secondary_swatches(nil)).to include("Opcional")
    expect(brand_swatches("#4F46E5")).not_to include("Opcional")
  end

  it "shows the five brand suggestions in the row" do
    html = brand_swatches(Branding::Palette::SUGGESTIONS.fetch(:brand_600).first)

    Branding::Palette::SUGGESTIONS.fetch(:brand_600).each { |hex| expect(html).to include(%(value="#{hex}")) }
  end

  it "opens the support suggestions with a none option carrying the empty value" do
    html = secondary_swatches(nil)

    expect(html).to include("Sem")
    expect(html).to include(%(value="" checked))
  end

  it "marks the stored suggestion in the row and never in the grid" do
    stored = Branding::Palette::SUGGESTIONS.fetch(:brand_600).last

    html = brand_swatches(stored)

    expect(html).to include(%(value="#{stored}" checked))
    expect(html.scan(%(value="#{stored}" checked)).size).to eq(1)
  end

  it "injects a stored color that is not a suggestion at the head of the row, keeping five options" do
    off_suggestion = "#7E22CE"

    document = Nokogiri::HTML5.fragment(brand_swatches(off_suggestion))
    row_radios = document.css("[data-row-option] input[type=radio]")

    expect(row_radios.map { |radio| radio["value"] }).to eq([ off_suggestion, *Branding::Palette::SUGGESTIONS.fetch(:brand_600).first(4) ])
    expect(document.at_css(%([data-row-option] input[value="#{off_suggestion}"])).key?("checked")).to be(true)
  end

  it "paints an off-palette stored color through the tenant sheet, never through the palette sheet" do
    html = brand_swatches("#123456")

    expect(html).to include("bg-brand-600")
    expect(html).not_to include(%(data-swatch="#123456"))
  end

  it "packs the whole palette into a grid of eight columns inside the plus" do
    document = Nokogiri::HTML5.fragment(brand_swatches(Branding::Palette.swatches.first))

    grid = document.at_css("details [data-swatch-grid]")
    expect(grid["class"]).to include("grid-cols-8")
    Branding::Palette.swatches.each { |hex| expect(grid.to_html).to include(%(data-swatch="#{hex}")) }
  end

  it "keeps the plus closed when the stored color is a swatch" do
    document = Nokogiri::HTML5.fragment(brand_swatches(Branding::Palette.swatches.first))

    expect(document.at_css("details").key?("open")).to be(false)
  end

  it "opens the plus and carries the typed code when the stored color is off the palette" do
    document = Nokogiri::HTML5.fragment(brand_swatches("#123456"))

    expect(document.at_css("details").key?("open")).to be(true)
    expect(document.at_css(%(input[name="branding[brand_600_custom]"]))["value"]).to eq("#123456")
  end

  it "reads the support color back through the support token, never the brand one" do
    html = secondary_swatches("#123456")

    expect(html).to include("bg-secondary-600")
    expect(html).not_to include("bg-brand-600")
  end

  it "paints each swatch through the served palette sheet, never an inline style attribute" do
    html = brand_swatches(Branding::Palette.swatches.first)

    expect(html).to include(%(data-swatch="#{Branding::Palette.swatches.first}"))
    expect(html).not_to include("style=")
  end
end
