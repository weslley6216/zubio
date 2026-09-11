require "rails_helper"

RSpec.describe Components::Menu, type: :component do
  let(:items) { [ [ "Painel", "/owner/dashboard" ], [ "Marca", "/owner/branding/edit" ] ] }

  it "lists every item it receives and closes with the theme row" do
    html = described_class.new(items: items).call

    expect(html).to include(%(href="/owner/dashboard"))
    expect(html).to include(%(href="/owner/branding/edit"))
    expect(html).to include(%(data-action="theme#toggle"))
    expect(html).to include(Components::ThemeToggle::LABEL)
  end

  it "hides itself at the width where the inline navigation takes over" do
    html = described_class.new(items: items).call

    expect(html).to include("sm:hidden")
    expect(html).to include(Components::Menu::LABEL)
  end

  it "marks the item the caller flagged as current and leaves the others resting" do
    html = described_class.new(items: [ [ "Painel", "/owner/dashboard", true ], [ "Marca", "/owner/branding/edit", false ] ]).call

    expect(html).to include(%(<a href="/owner/dashboard" aria-current="page"))
    expect(html).to include(described_class::CURRENT_CLASS)
    expect(html).not_to include(%(<a href="/owner/branding/edit" aria-current="page"))
  end

  it "paints the current item with the secondary color, so a second brand color shows on a phone too" do
    html = described_class.new(items: [ [ "Painel", "/owner/dashboard", true ] ]).call

    expect(described_class::CURRENT_CLASS).to include("bg-secondary-accent")
    expect(html).to include("bg-secondary-accent")
  end

  it "leaves every item resting when the caller flags none of them" do
    html = described_class.new(items: items).call

    expect(html).not_to include(%(aria-current="page"))
    expect(html).to include(described_class::RESTING_CLASS)
  end

  it "puts an extra row above the theme row when the caller supplies one" do
    html = described_class.new(items: items).call { |menu| menu.plain("Sair") }

    expect(html).to include("Sair")
    expect(html.index("Sair")).to be < html.index(Components::ThemeToggle::LABEL)
  end
end
