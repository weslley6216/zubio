require "rails_helper"

RSpec.describe Components::Owner::Emblem, type: :component do
  let(:tenant) { build(:tenant, name: "Barbearia do Zé") }
  let(:branding) { build(:branding, tenant: tenant) }

  it "shows the initial of the establishment on the brand accent when there is no logo" do
    html = described_class.new(tenant: tenant, branding: branding, size: :medium).call

    expect(html).to include(">B</span>")
    expect(html).to include("data-brand-initial")
    expect(html).to include("bg-brand-accent")
    expect(html).not_to include("<img")
  end

  it "takes the size its caller asks for" do
    small = described_class.new(tenant: tenant, branding: branding, size: :small).call
    large = described_class.new(tenant: tenant, branding: branding, size: :large).call

    expect(small).to include(described_class::SIZES.fetch(:small))
    expect(large).to include(described_class::SIZES.fetch(:large))
    expect(small).not_to include(described_class::SIZES.fetch(:large))
  end

  it "refuses a size it does not draw" do
    expect { described_class.new(tenant: tenant, branding: branding, size: :huge).call }.to raise_error(KeyError)
  end

  it "gives the large size the canvas radius and initial" do
    large = described_class.new(tenant: tenant, branding: branding, size: :large).call

    expect(large).to include("rounded-[14px]")
    expect(large).to include("text-[21px]")
  end

  it "gives the showcase size the public page's square and initial" do
    showcase = described_class.new(tenant: tenant, branding: branding, size: :showcase).call

    expect(showcase).to include("h-14 w-14")
    expect(showcase).to include("rounded-[16px]")
    expect(showcase).to include("text-[24px]")
  end

  it "sets the showcase initial's line height to normal and leaves the panel sizes alone" do
    showcase = described_class.new(tenant: tenant, branding: branding, size: :showcase).call
    medium = described_class.new(tenant: tenant, branding: branding, size: :medium).call

    expect(showcase).to include("leading-[normal]")
    expect(medium).not_to include("leading-[normal]")
  end

  it "paints the initial with the brand accent tone by default" do
    html = described_class.new(tenant: tenant, branding: branding, size: :medium).call

    expect(html).to include("bg-brand-accent")
    expect(html).to include("text-on-brand-accent")
  end

  it "paints the initial translucent on-brand when asked for that tone" do
    html = described_class.new(tenant: tenant, branding: branding, size: :showcase, tone: :translucent).call

    expect(html).to include("bg-on-brand/20")
    expect(html).to include("text-on-brand")
    expect(html).not_to include("bg-brand-accent")
  end

  it "still shows the logo image in the translucent tone when there is one" do
    logo_branding = create(:branding, :with_logo, tenant: tenant)

    html = render_phlex(described_class.new(tenant: tenant, branding: logo_branding, size: :showcase, tone: :translucent))

    expect(html).to include("<img")
  end
end
