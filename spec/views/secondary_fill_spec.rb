require "rails_helper"

RSpec.describe "Secondary color discipline" do
  def secondary_fill_pattern = /\bbg-secondary(?!-soft(?![\w-]))(?:-[\w-]+)?(?![\w-])/

  def color_chip_path = Rails.root.join("app/components/color_chip.rb").to_s

  it "keeps the secondary color off every background in views and components, but the chip that shows the chosen color" do
    offenders = Dir[Rails.root.join("app/{views,components}/**/*.rb")].reject { |path| path == color_chip_path }.select do |path|
      File.read(path).match?(secondary_fill_pattern)
    end

    expect(offenders).to be_empty
  end

  it "flags a full secondary fill when one exists" do
    probe = %(span(class: "rounded-full hover:bg-secondary-600 px-3"))

    expect(probe).to match(secondary_fill_pattern)
  end

  it "lets the light pair of the secondary color through" do
    probe = %(span(class: "bg-secondary-soft text-secondary-soft-ink"))

    expect(probe).not_to match(secondary_fill_pattern)
  end

  it "keeps the color chip as a live exception, filled with the secondary color" do
    expect(File.read(color_chip_path)).to match(secondary_fill_pattern)
  end
end
