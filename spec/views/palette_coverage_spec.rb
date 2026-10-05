require "rails_helper"

RSpec.describe "Theme token discipline" do
  let(:named_palette) do
    /\b(?:bg|text|border|ring|from|to|via)-(?:slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-\d{2,3}\b/
  end

  it "keeps every themed surface off Tailwind's named palette" do
    sources = Dir[Rails.root.join("app/{views,components,javascript}/**/*.{rb,js}")]

    offenders = sources.select { |path| File.read(path).match?(named_palette) }

    expect(offenders).to be_empty
  end

  it "flags a named palette class when one exists" do
    expect(%(p(class: "mt-1 text-sm text-red-700"))).to match(named_palette)
  end

  it "lets a theme token through" do
    expect(%(p(class: "mt-1 text-sm text-danger bg-surface-2"))).not_to match(named_palette)
  end
end
