require "rails_helper"

RSpec.describe Components::Owner::Onboarding::Screen, type: :component do
  def screen(**overrides, &block)
    defaults = { section: "logo", group: "Sua marca", position: 3, total: 5, primary: "Continuar" }
    described_class.new(**defaults.merge(overrides)).call(&block || proc { "corpo" })
  end

  it "carries the group and the counter in the header" do
    html = screen

    expect(html).to include("Sua marca")
    expect(html).to include("3 de 5")
  end

  it "fills one bar segment per answered question and leaves the rest empty" do
    document = Nokogiri::HTML5.fragment(screen(position: 4))
    segments = document.css("[data-progress-bar] > div")

    expect(segments.length).to eq(5)
    expect(segments.take(4).map { |segment| segment["class"] }).to all(include("bg-brand-600"))
    expect(segments.last["class"]).to include("bg-line")
  end

  it "anchors a next button by default and a submit when asked" do
    expect(screen).to include("onboarding#next")
    expect(screen(submit: true)).to include(%(type="submit"))
  end

  it "offers a secondary text button only when given one" do
    expect(screen(secondary: "Pular por enquanto")).to include("Pular por enquanto")
    expect(screen).not_to include("Pular por enquanto")
  end

  it "yields the body between header and footer" do
    expect(screen { "meu corpo" }).to include("meu corpo")
  end

  it "hides the section when asked, so the client can reveal only the open question" do
    document = Nokogiri::HTML5.fragment(screen(hidden: true))

    expect(document.at_css(%([data-onboarding-target="section"])).key?("hidden")).to be(true)
  end

  it "shows the section by default" do
    document = Nokogiri::HTML5.fragment(screen)

    expect(document.at_css(%([data-onboarding-target="section"]))["hidden"]).to be_nil
  end
end
