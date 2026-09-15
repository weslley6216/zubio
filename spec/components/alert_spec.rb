require "rails_helper"

RSpec.describe Components::Alert, type: :component do
  def alert(html) = Nokogiri::HTML5.fragment(html).at_css("[data-alert]")

  def classes(html) = alert(html)["class"].split

  it "outlines a confirmation in the success color on the neutral surface" do
    html = described_class.new(text: "Marca atualizada.", tone: :success).call

    expect(classes(html)).to include("border-success", "bg-surface", "text-ink")
    expect(classes(html)).not_to include("border-danger")
  end

  it "outlines a refusal in the danger color on the neutral surface" do
    html = described_class.new(text: "E-mail ou senha inválidos.", tone: :danger).call

    expect(classes(html)).to include("border-danger", "bg-surface", "text-ink")
    expect(classes(html)).not_to include("border-success")
  end

  it "tints the background of no tone" do
    backgrounds = described_class::TONES.each_key.flat_map do |tone|
      classes(described_class.new(text: "Salvo", tone: tone).call).grep(/\Abg-/)
    end

    expect(backgrounds.uniq).to eq([ "bg-surface" ])
  end

  it "marks each tone with its own icon in the tone's color, hidden from assistive technology" do
    success = alert(described_class.new(text: "Marca atualizada.", tone: :success).call).at_css("svg")
    danger = alert(described_class.new(text: "E-mail ou senha inválidos.", tone: :danger).call).at_css("svg")

    expect(success["class"].split).to include("text-success")
    expect(danger["class"].split).to include("text-danger")
    expect([ success["aria-hidden"], danger["aria-hidden"] ]).to eq(%w[true true])
    expect(success.to_html).not_to eq(danger.to_html)
  end

  it "reads as the message alone, with the icon adding no text" do
    html = described_class.new(text: "E-mail ou senha inválidos.", tone: :danger).call

    expect(alert(html).text).to eq("E-mail ou senha inválidos.")
  end

  it "refuses a tone with no palette behind it" do
    expect { described_class.new(text: "Salvo", tone: :warning).call }.to raise_error(KeyError)
  end
end
