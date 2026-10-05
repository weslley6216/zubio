require "rails_helper"

RSpec.describe Components::Owner::BrandQuestion::Colors, type: :component do
  let(:tenant) { build(:tenant, name: "Barbearia do Zé") }

  it "asks only about the colors, with its own title and subtitle" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_600: "#2C6CB0")).call

    expect(html).to include(described_class::TITLE)
    expect(html).to include(described_class::SUBTITLE)
  end

  it "offers a brand group and a support group, each labelled" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_600: "#2C6CB0")).call

    expect(html).to include(%(<fieldset aria-label="#{described_class::BRAND_LABEL}"))
    expect(html).to include(%(<fieldset aria-label="#{described_class::SECONDARY_LABEL}"))
  end

  it "reads the stored brand and support colors back into their groups" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_600: "#1E60C4", brand_secondary_600: "#BE123C")).call

    expect(html).to include(%(value="#1E60C4" checked))
    expect(html).to include(%(value="#BE123C" checked))
  end

  it "marks the support color optional and explains when it is for" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_600: "#2C6CB0")).call

    expect(html).to include(described_class::SECONDARY_OPTIONAL)
    expect(html).to include(described_class::SECONDARY_HELP)
  end

  it "drives the live preview from the color controller" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_600: "#2C6CB0")).call

    expect(html).to include(%(data-controller="color-swatch"))
    expect(html).to include("data-color-swatch-target=\"preview\"")
    expect(html).to include("data-preview-brand")
  end

  it "matches the canvas copy for the two legends and shows the translucent emblem in the preview" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_600: "#2C6CB0")).call

    expect(html).to include("botões e cabeçalho")
    expect(html).to include("detalhes e destaques")
    expect(html).to include(">z</span>")
    expect(html).to include("bg-white/22")
  end

  it "surfaces the brand color error beside its group" do
    branding = build(:branding, tenant: tenant, brand_600: "#7A7A7A")
    branding.valid?

    html = described_class.new(tenant: tenant, branding: branding).call

    expect(html).to include("text-danger")
  end

  it "sizes the question title to the canvas 26px" do
    document = Nokogiri::HTML5.fragment(described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_600: "#2C6CB0")).call)

    expect(document.at_css("h1")["class"]).to include("text-[26px]")
  end

  it "wraps the preview label as the top strip of a white rounded card" do
    document = Nokogiri::HTML5.fragment(described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_600: "#2C6CB0")).call)

    card = document.at_css("[data-color-swatch-target='preview']")
    strip = card.children.first
    expect(card["class"]).to include("rounded-2xl")
    expect(card["class"]).to include("bg-surface")
    expect(strip.text).to eq(described_class::PREVIEW_LABEL)
    expect(strip["class"]).to include("border-b")
  end

  it "runs the color header edge to edge and lets the book action grow" do
    document = Nokogiri::HTML5.fragment(described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_600: "#2C6CB0")).call)

    header = document.at_css(".bg-brand-accent")
    book = document.css("span").find { |node| node.text == described_class::PREVIEW_BOOK }
    services = document.css("span").find { |node| node.text == described_class::PREVIEW_SERVICES }
    expect(header["class"]).not_to include("rounded")
    expect(book["class"]).to include("flex-grow")
    expect(book["class"]).to include("h-11")
    expect(services["class"]).not_to include("flex-grow")
    expect(services["class"]).to include("h-11")
  end
end
