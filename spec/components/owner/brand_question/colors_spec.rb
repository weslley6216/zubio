require "rails_helper"

RSpec.describe Components::Owner::BrandQuestion::Colors, type: :component do
  let(:tenant) { build(:tenant, name: "Barbearia do Zé") }

  it "asks about the page colors, with its own title and subtitle" do
    html = described_class.new(tenant: tenant, branding: build(:branding, :with_background, tenant: tenant)).call

    expect(html).to include(described_class::TITLE)
    expect(html).to include(described_class::SUBTITLE)
  end

  it "offers a background group and an accent group, each labelled, with no support-color group" do
    html = described_class.new(tenant: tenant, branding: build(:branding, :with_background, tenant: tenant)).call

    expect(html).to include(%(<fieldset aria-label="#{described_class::BACKGROUND_LABEL}"))
    expect(html).to include(%(<fieldset aria-label="#{described_class::ACCENT_LABEL}"))
    expect(html).not_to include("Cor de apoio")
  end

  it "reads the stored background and accent colors back into their groups" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_background: "#1F4D3A", brand_600: "#F2B33D")).call

    expect(html).to include(%(value="#1F4D3A" checked))
    expect(html).to include(%(value="#F2B33D" checked))
  end

  it "marks no background radio when the stored background is nil" do
    document = Nokogiri::HTML5.fragment(described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_background: nil, brand_600: "#F2B33D")).call)

    background_fieldset = document.css("fieldset").find { |node| node["aria-label"] == described_class::BACKGROUND_LABEL }
    expect(background_fieldset.css("input[type=radio][checked]")).to be_empty
  end

  it "drives the live preview from the color controller" do
    html = described_class.new(tenant: tenant, branding: build(:branding, :with_background, tenant: tenant)).call

    expect(html).to include(%(data-controller="color-swatch"))
    expect(html).to include("data-color-swatch-target=\"preview\"")
    expect(html).to include("data-preview-bg")
    expect(html).to include("data-preview-accent")
  end

  it "falls back to the none background in the preview when there is no stored background" do
    html = described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant, brand_background: nil, brand_600: "#F2B33D")).call

    expect(html).to include(%(data-preview-bg="none"))
  end

  it "surfaces the background and accent errors beside their own group" do
    branding = build(:branding, tenant: tenant, brand_background: "#16324A", brand_600: "#1E3A55")
    branding.valid?

    html = described_class.new(tenant: tenant, branding: branding).call

    expect(html).to include("text-danger")
  end

  it "sizes the question title to the canvas 24px" do
    document = Nokogiri::HTML5.fragment(described_class.new(tenant: tenant, branding: build(:branding, :with_background, tenant: tenant)).call)

    expect(document.at_css("h1")["class"]).to include("text-[24px]")
  end

  it "stacks the heading, the two groups and the preview 14px apart on the canvas normal line height" do
    document = Nokogiri::HTML5.fragment(described_class.new(tenant: tenant, branding: build(:branding, :with_background, tenant: tenant)).call)

    root = document.at_css("[data-controller='color-swatch']")
    expect(root["class"].split).to include("flex", "flex-col", "gap-3.5", "leading-[normal]")
    expect(document.at_css("h1")["class"]).not_to include("leading-")
  end

  it "paints the preview panel, card and book action from the theme tokens, with the caption outside the panel" do
    document = Nokogiri::HTML5.fragment(described_class.new(tenant: tenant, branding: build(:branding, :with_background, tenant: tenant)).call)

    panel = document.at_css("[data-color-swatch-target='preview'] > div")
    expect(panel["class"]).to include("bg-(--theme-bg)")
    card = panel.at_css("div")
    expect(card["class"]).to include("bg-(--theme-card)")
    expect(card.at_xpath(".//*[normalize-space(text())='#{described_class::PREVIEW_SERVICE_NAME}']")["class"]).to include("text-(--theme-on-card)")
    expect(card.at_xpath(".//*[normalize-space(text())='#{described_class::PREVIEW_SERVICE_META}']")["class"]).to include("text-(--theme-on-card-muted)")
    book = panel.css("span").find { |node| node.text == described_class::PREVIEW_BOOK }
    expect(book["class"]).to include("bg-(--theme-accent)", "text-(--theme-on-accent)")
    caption = document.at_css("[data-color-swatch-target='preview'] > p")
    expect(caption.text).to eq(described_class::PREVIEW_CAPTION)
    expect(document.at_css("[data-color-swatch-target='preview']")["class"].split).to include("flex", "flex-col", "gap-3.5")
  end
end
