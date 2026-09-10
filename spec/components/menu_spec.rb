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

  it "puts an extra row above the theme row when the caller supplies one" do
    html = described_class.new(items: items).call { |menu| menu.plain("Sair") }

    expect(html).to include("Sair")
    expect(html.index("Sair")).to be < html.index(Components::ThemeToggle::LABEL)
  end
end
