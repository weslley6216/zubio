require "rails_helper"

RSpec.describe "Theme token discipline" do
  # Only Tailwind's named palette is guarded here. `white` and `black` are
  # deliberately out of scope: the landing paints them over a fixed brand
  # surface and covers those pairs with its own contrast examples.
  def named_palette_pattern
    names = %w[
      slate gray zinc neutral stone red orange amber yellow lime green
      emerald teal cyan sky blue indigo violet purple fuchsia pink rose
    ]

    /\b(?:bg|text|border|ring|from|to|via)-(?:#{names.join("|")})-\d{2,3}\b/
  end

  it "keeps every themed surface off Tailwind's named palette" do
    offenders = Dir[Rails.root.join("app/{views,components,javascript}/**/*.{rb,js}")].select do |path|
      File.read(path).match?(named_palette_pattern)
    end

    expect(offenders).to be_empty
  end

  it "flags a named palette class when one exists" do
    probe = %(p(class: "mt-1 text-sm text-red-700"))

    expect(probe).to match(named_palette_pattern)
  end
end
