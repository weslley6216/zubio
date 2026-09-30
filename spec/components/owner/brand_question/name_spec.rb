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

  it "sizes the title to 26px and the name field to the canvas" do
    document = Nokogiri::HTML5.fragment(body)
    field = document.at_css("#tenant_name")

    expect(document.at_css("h1")["class"]).to include("text-[26px]")
    expect(field["class"]).to include("h-[58px]")
    expect(field["class"]).to include("border-2")
    expect(field["class"]).to include("border-brand-600")
    expect(field["class"]).to include("rounded-[14px]")
    expect(field["class"]).to include("text-[20px]")
  end

  it "drops the counter 16px below the field in the subtle ink" do
    document = Nokogiri::HTML5.fragment(body)
    counter = document.at_css("[data-name-counter-target='readout']")

    expect(counter["class"]).to include("mt-4")
    expect(counter["class"]).to include("text-ink-subtle")
  end

  it "gives the address card a white background and the section-label eyebrow" do
    document = Nokogiri::HTML5.fragment(body)
    label = document.css("span").find { |node| node.text == described_class::ADDRESS_LABEL }

    expect(label["class"]).to include(Components::Form::Styles::SECTION_LABEL)
    expect(label.parent["class"]).to include("bg-surface")
    expect(label.parent["class"]).not_to include("bg-surface-2")
  end
end
