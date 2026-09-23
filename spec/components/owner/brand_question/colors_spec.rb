require "rails_helper"

RSpec.describe Components::Owner::BrandQuestion::Colors, type: :component do
  let(:tenant) { build(:tenant, name: "Barbearia do Zé") }

  def body(branding)
    described_class.new(tenant: tenant, branding: branding).call
  end

  it "asks only about the colors, with its own title and subtitle" do
    html = body(build(:branding, tenant: tenant, brand_600: "#2C6CB0"))

    expect(html).to include(described_class::TITLE)
    expect(html).to include(described_class::SUBTITLE)
  end

  it "offers a brand group and a support group, each labelled" do
    html = body(build(:branding, tenant: tenant, brand_600: "#2C6CB0"))

    expect(html).to include(%(<fieldset aria-label="#{described_class::BRAND_LABEL}"))
    expect(html).to include(%(<fieldset aria-label="#{described_class::SECONDARY_LABEL}"))
  end

  it "reads the stored brand and support colors back into their groups" do
    html = body(build(:branding, tenant: tenant, brand_600: "#1E60C4", brand_secondary_600: "#BE123C"))

    expect(html).to include(%(value="#1E60C4" checked))
    expect(html).to include(%(value="#BE123C" checked))
  end

  it "marks the support color optional and explains when it is for" do
    html = body(build(:branding, tenant: tenant, brand_600: "#2C6CB0"))

    expect(html).to include(described_class::SECONDARY_OPTIONAL)
    expect(html).to include(described_class::SECONDARY_HELP)
  end

  it "drives the live preview from the color controller" do
    html = body(build(:branding, tenant: tenant, brand_600: "#2C6CB0"))

    expect(html).to include(%(data-controller="color-swatch"))
    expect(html).to include("data-color-swatch-target=\"preview\"")
    expect(html).to include("data-preview-brand")
  end

  it "matches the canvas copy for the two legends and shows the translucent emblem in the preview" do
    html = body(build(:branding, tenant: tenant, brand_600: "#2C6CB0"))

    expect(html).to include("botões e cabeçalho")
    expect(html).to include("detalhes e destaques")
    expect(html).to include(">z</span>")
    expect(html).to include("bg-white/22")
  end

  it "surfaces the brand color error beside its group" do
    branding = build(:branding, tenant: tenant, brand_600: "#7A7A7A")
    branding.valid?

    expect(body(branding)).to include("text-danger")
  end
end
