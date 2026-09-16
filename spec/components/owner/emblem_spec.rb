require "rails_helper"

RSpec.describe Components::Owner::Emblem, type: :component do
  let(:tenant) { build(:tenant, name: "Barbearia do Zé") }
  let(:branding) { build(:branding, tenant: tenant) }

  it "shows the initial of the establishment on the brand accent when there is no logo" do
    html = described_class.new(tenant: tenant, branding: branding, size: :medium).call

    expect(html).to include(">B</span>")
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
end
