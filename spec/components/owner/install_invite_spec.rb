require "rails_helper"

RSpec.describe Components::Owner::InstallInvite, type: :component do
  it "is born hidden at the root and in both variants" do
    html = render_phlex(described_class.new(name: "Barbearia do Zé", icon: nil, initial: "B"))

    fragment = Nokogiri::HTML5.fragment(html)
    expect(fragment.at_css("[data-controller='pwa-install']")["hidden"]).not_to be_nil
    expect(fragment.at_css("[data-pwa-install-target='action']")["hidden"]).not_to be_nil
    expect(fragment.at_css("[data-pwa-install-target='instructions']")["hidden"]).not_to be_nil
  end

  it "falls back to the establishment initial on the brand color when there is no icon" do
    html = render_phlex(described_class.new(name: "Barbearia do Zé", icon: nil, initial: "B"))

    initial = Nokogiri::HTML5.fragment(html).at_css("[data-brand-initial]")
    expect(initial.text).to eq("B")
    expect(initial["class"]).to include("bg-brand-600", "text-on-brand")
    expect(html).not_to include("<img")
  end

  it "shows the establishment icon with the name as its alt when an icon is given" do
    branding = create(:branding, :with_logo)

    html = render_phlex(described_class.new(name: "Estúdio Aurora", icon: branding.invite_icon, initial: "E"))

    image = Nokogiri::HTML5.fragment(html).at_css("img")
    expect(image["src"]).to include("/rails/active_storage/representations/proxy/")
    expect(image["alt"]).to eq("Estúdio Aurora")
  end

  it "offers the install action and a defer in the action card" do
    html = render_phlex(described_class.new(name: "Barbearia do Zé", icon: nil, initial: "B"))

    action = Nokogiri::HTML5.fragment(html).at_css("[data-pwa-install-target='action']")
    expect(action.text).to include(described_class::INSTALL_LABEL, described_class::DISMISS_LABEL)
    expect(action.at_css("[data-action='pwa-install#install']")).not_to be_nil
  end

  it "spells the two Safari steps in the instructions card and never offers to install there" do
    html = render_phlex(described_class.new(name: "Barbearia do Zé", icon: nil, initial: "B"))

    instructions = Nokogiri::HTML5.fragment(html).at_css("[data-pwa-install-target='instructions']")
    expect(instructions.text).to include("Compartilhar", "Adicionar à Tela de Início", described_class::INSTALLED_LABEL)
    expect(instructions.text).not_to include(described_class::INSTALL_LABEL)
  end

  it "wires both the defer and the already-installed buttons to dismiss" do
    html = render_phlex(described_class.new(name: "Barbearia do Zé", icon: nil, initial: "B"))

    dismissers = Nokogiri::HTML5.fragment(html).css("[data-action='pwa-install#dismiss']")
    expect(dismissers.map(&:text)).to contain_exactly(described_class::DISMISS_LABEL, described_class::INSTALLED_LABEL)
  end

  it "dresses the card in theme tokens so it reads in light and dark" do
    html = render_phlex(described_class.new(name: "Barbearia do Zé", icon: nil, initial: "B"))

    fragment = Nokogiri::HTML5.fragment(html)
    expect(fragment.at_css("[data-pwa-install-target='action']")["class"]).to include("bg-surface", "border-line")
    expect(fragment.at_css("[data-pwa-install-target='instructions'] [class*='bg-surface-2']")).not_to be_nil
  end

  it "does not render the reference-board eyebrows or the dashed cross-persona note" do
    html = render_phlex(described_class.new(name: "Barbearia do Zé", icon: nil, initial: "B"))

    expect(html).to include(described_class::TITLE)
    expect(html).not_to include("prompt nativo")
    expect(html).not_to include("instrução manual")
    expect(html).not_to include("O mesmo convite aparece")
  end
end
