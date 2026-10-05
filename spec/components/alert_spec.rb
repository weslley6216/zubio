require "rails_helper"

RSpec.describe Components::Alert, type: :component do
  it "outlines a confirmation in the success color on the neutral surface" do
    alert = Nokogiri::HTML5.fragment(described_class.new(text: "Marca atualizada.", tone: :success).call).at_css("[data-alert]")

    expect(alert["class"].split).to include("border-success", "bg-surface", "text-ink")
    expect(alert["class"].split).not_to include("border-danger")
  end

  it "outlines a refusal in the danger color on the neutral surface" do
    alert = Nokogiri::HTML5.fragment(described_class.new(text: "E-mail ou senha inválidos.", tone: :danger).call).at_css("[data-alert]")

    expect(alert["class"].split).to include("border-danger", "bg-surface", "text-ink")
    expect(alert["class"].split).not_to include("border-success")
  end

  it "tints the background of no tone" do
    alerts = described_class::TONES.each_key.map do |tone|
      Nokogiri::HTML5.fragment(described_class.new(text: "Salvo", tone: tone).call).at_css("[data-alert]")
    end

    expect(alerts.flat_map { |alert| alert["class"].split.grep(/\Abg-/) }.uniq).to eq([ "bg-surface" ])
  end

  it "marks a success with its icon in the success color, hidden from assistive technology" do
    icon = Nokogiri::HTML5.fragment(described_class.new(text: "Marca atualizada.", tone: :success).call).at_css("[data-alert] svg")

    expect(icon["class"].split).to include("text-success")
    expect(icon["aria-hidden"]).to eq("true")
  end

  it "marks a refusal with its own icon in the danger color, hidden from assistive technology" do
    success_icon = Nokogiri::HTML5.fragment(described_class.new(text: "Marca atualizada.", tone: :success).call).at_css("[data-alert] svg")

    danger_icon = Nokogiri::HTML5.fragment(described_class.new(text: "E-mail ou senha inválidos.", tone: :danger).call).at_css("[data-alert] svg")

    expect(danger_icon["class"].split).to include("text-danger")
    expect(danger_icon["aria-hidden"]).to eq("true")
    expect(danger_icon.to_html).not_to eq(success_icon.to_html)
  end

  it "reads as the message alone, with the icon adding no text" do
    alert = Nokogiri::HTML5.fragment(described_class.new(text: "E-mail ou senha inválidos.", tone: :danger).call).at_css("[data-alert]")

    expect(alert.text).to eq("E-mail ou senha inválidos.")
  end

  it "refuses a tone with no palette behind it" do
    expect { described_class.new(text: "Salvo", tone: :warning).call }.to raise_error(KeyError)
  end
end
