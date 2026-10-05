require "rails_helper"

RSpec.describe "Secondary color discipline" do
  let(:secondary_fill) { /\bbg-secondary(?!-soft(?![\w-]))(?:-[\w-]+)?(?![\w-])/ }
  let(:color_chip_path) { Rails.root.join("app/components/color_chip.rb").to_s }

  it "keeps the secondary color off every background in views and components, but the chip that shows the chosen color" do
    sources = Dir[Rails.root.join("app/{views,components,javascript}/**/*.{rb,js}")] - [ color_chip_path ]

    offenders = sources.select { |path| File.read(path).match?(secondary_fill) }

    expect(offenders).to be_empty
  end

  it "flags a full secondary fill when one exists" do
    expect(%(span(class: "rounded-full hover:bg-secondary-600 px-3"))).to match(secondary_fill)
  end

  it "lets the light pair of the secondary color through" do
    expect(%(span(class: "bg-secondary-soft text-secondary-soft-ink"))).not_to match(secondary_fill)
  end

  it "keeps the color chip as a live exception, filled with the secondary color" do
    expect(File.read(color_chip_path)).to match(secondary_fill)
  end
end
