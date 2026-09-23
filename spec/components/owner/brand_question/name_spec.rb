require "rails_helper"

RSpec.describe Components::Owner::BrandQuestion::Name, type: :component do
  let(:tenant) { build(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé") }

  def body
    described_class.new(tenant: tenant, branding: build(:branding, tenant: tenant)).call
  end

  it "asks only for the name, with its own title and subtitle" do
    expect(body).to include(described_class::TITLE)
    expect(body).to include(described_class::SUBTITLE)
  end

  it "reads the stored name into a single field capped at the model limit" do
    expect(body).to include(%(name="tenant[name]"))
    expect(body).to include(%(value="Barbearia do Zé"))
    expect(body).to include(%(maxlength="#{Tenant::NAME_MAX_LENGTH}"))
  end

  it "counts the current length against the limit on the server" do
    expect(body).to include("15 de #{Tenant::NAME_MAX_LENGTH} caracteres")
  end

  it "shows the establishment address from the canonical host, not remounted from the name" do
    expect(body).to include(described_class::ADDRESS_LABEL)
    expect(body).to include("barbearia-do-ze.zubio.com.br")
  end

  it "shows the emblem, the brand name and the address in the derived card" do
    tenant = Tenant.new(name: "Barbearia do Zé")
    branding = ActsAsTenant.with_tenant(tenant) { Branding.new(tenant: tenant, brand_600: "#2C6CB0") }

    html = described_class.new(tenant: tenant, branding: branding, deriving: true).call

    expect(html).to include("Barbearia do Zé")
    expect(html).to include(%(data-brand-address-target="name"))
    expect(html).to include(%(data-brand-address-target="address"))
    expect(html).to include(%(data-brand-address-target="namePreview"))
    expect(html).to include(">B</span>")
  end
end
