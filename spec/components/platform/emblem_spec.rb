require "rails_helper"

RSpec.describe Components::Platform::Emblem, type: :component do
  it "stamps the Zubio z on the brand accent for the header" do
    html = described_class.new(size: :header).call

    expect(html).to include(">z</span>")
    expect(html).to include("bg-brand-accent")
  end

  it "grows the mark for the onboarding welcome" do
    expect(described_class.new(size: :onboarding).call).to include("h-13")
  end
end
