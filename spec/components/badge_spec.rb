require "rails_helper"

RSpec.describe Components::Badge, type: :component do
  it "paints the accent tone with the brand accent" do
    html = described_class.new(text: "Comece por aqui", tone: :accent).call

    expect(html).to include("bg-brand-accent")
    expect(html).to include("text-on-brand-accent")
    expect(html).not_to include("bg-surface-3")
  end

  it "paints the muted tone off the brand" do
    html = described_class.new(text: "Desativado", tone: :muted).call

    expect(html).to include("bg-surface-3")
    expect(html).to include("text-ink-muted")
    expect(html).not_to include("bg-brand-accent")
  end

  it "keeps the pill shape on every tone" do
    shapes = described_class::TONES.each_key.map do |tone|
      described_class.new(text: "Desativado", tone: tone).call.include?(described_class::BASE_CLASS)
    end

    expect(shapes).to all(be(true))
    expect(shapes.size).to eq(described_class::TONES.size)
  end

  it "refuses a tone with no palette behind it" do
    expect { described_class.new(text: "Novo cliente", tone: :warning).call }.to raise_error(KeyError)
  end
end
