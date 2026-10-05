require "rails_helper"

RSpec.describe Components::Owner::Onboarding::Screen, type: :component do
  it "carries the group and the counter in the header" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar").call { "corpo" }

    expect(html).to include("Sua marca")
    expect(html).to include("3 de 5")
  end

  it "fills one bar segment per answered question and leaves the rest empty" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 4, total: 5, primary: "Continuar").call { "corpo" }

    segments = Nokogiri::HTML5.fragment(html).css("[data-progress-bar] > div")
    expect(segments.length).to eq(5)
    expect(segments.take(4).map { |segment| segment["class"] }).to all(include("bg-brand-600"))
    expect(segments.last["class"]).to include("bg-line")
  end

  it "anchors a next button by default" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar").call { "corpo" }

    expect(html).to include("onboarding#next")
    expect(html).not_to include(%(type="submit"))
  end

  it "anchors a submit when asked" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar", submit: true).call { "corpo" }

    expect(html).to include(%(type="submit"))
  end

  it "offers a secondary text button when given one" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar", secondary: "Pular por enquanto").call { "corpo" }

    expect(html).to include("Pular por enquanto")
  end

  it "offers no secondary text button when not given one" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar").call { "corpo" }

    expect(html).to include("Continuar")
    expect(html).not_to include("Pular por enquanto")
  end

  it "yields the body between header and footer" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar").call { "meu corpo" }

    expect(html).to include("meu corpo")
  end

  it "hides the section when asked, so the client can reveal only the open question" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar", hidden: true).call { "corpo" }

    expect(Nokogiri::HTML5.fragment(html).at_css(%([data-onboarding-target="section"])).key?("hidden")).to be(true)
  end

  it "shows the section by default" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar").call { "corpo" }

    expect(Nokogiri::HTML5.fragment(html).at_css(%([data-onboarding-target="section"]))["hidden"]).to be_nil
  end

  it "names the icon-only back button for assistive tech and for clicking it by name" do
    html = described_class.new(section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar").call { "corpo" }

    expect(Nokogiri::HTML5.fragment(html).at_css(%([data-onboarding-target="back"]))["aria-label"]).to eq("Voltar")
  end
end
