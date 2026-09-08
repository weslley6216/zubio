require "rails_helper"

RSpec.describe Components::ThemeToggle, type: :component do
  it "hides the button on a phone when another toggle lives in the phone menu" do
    html = described_class.new(hidden_on_phone: true).call

    expect(html).to include("hidden sm:grid")
  end

  it "keeps the button visible on a phone when it is the only toggle" do
    html = described_class.new(hidden_on_phone: false).call

    expect(html).not_to include("hidden sm:grid")
    expect(html).to include(%(aria-label="Trocar o tema"))
  end
end
