require "rails_helper"

RSpec.describe "Design token coverage" do
  def default_palette_pattern
    names = %w[
      slate gray zinc neutral stone red orange amber yellow lime green
      emerald teal cyan sky blue indigo violet purple fuchsia pink rose
    ]

    /\b(?:bg|text|border|ring|from|to|via)-(?:#{names.join("|")})-\d{2,3}\b/
  end

  it "renders every surface from the theme, never from Tailwind's default palette" do
    offenders = Dir[Rails.root.join("app/{views,components}/**/*.rb")].select do |path|
      File.read(path).match?(default_palette_pattern)
    end

    expect(offenders).to be_empty
  end

  it "flags a raw palette class when one exists" do
    probe = %(p(class: "mt-1 text-sm text-red-700"))

    expect(probe).to match(default_palette_pattern)
  end
end
