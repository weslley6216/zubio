require "rails_helper"

RSpec.describe "Client theme discipline" do
  let(:neutral_palette) do
    /\b(?:bg|text)-(?:brand(?:-\d{2,3})?|on-brand|canvas|surface(?:-\d)?|ink(?:-\w+)?)\b/
  end

  it "keeps every client view off the neutral palette" do
    sources = Dir[Rails.root.join("app/views/client/**/*.rb")]

    offenders = sources.select { |path| File.read(path).match?(neutral_palette) }

    expect(offenders).to be_empty
  end

  it "flags a neutral token when one exists" do
    expect(%(div(class: "bg-brand-600 text-on-brand"))).to match(neutral_palette)
  end

  it "lets a theme token through" do
    expect(%(div(class: "bg-(--theme-accent) text-(--theme-on-accent)"))).not_to match(neutral_palette)
  end
end
