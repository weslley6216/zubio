require "rails_helper"

RSpec.describe Components::Service::Card, type: :component do
  let(:tenant) { build(:tenant) }
  let(:service) { build(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45) }

  it "renders the name as a link to the given target, with the duration" do
    html = described_class.new(service: service, href: "/services/1/booking/new").call

    expect(html).to include(%(<a href="/services/1/booking/new" class="#{described_class::NAME_CLASS}">Corte feminino</a>))
    expect(html).to include("45min")
  end

  it "renders a badge beside the name when one is given" do
    badge = Components::Badge.new(text: "Desativado", tone: :muted)

    html = described_class.new(service: service, href: "/x", badge: badge).call

    expect(html).to include("Desativado")
  end

  it "renders no badge when none is given" do
    html = described_class.new(service: service, href: "/x").call

    expect(html).not_to include("Desativado")
  end

  it "renders the description with its data hook when one is given" do
    html = described_class.new(service: service, href: "/x", description: "Inclui lavagem.").call

    expect(html).to include("data-description")
    expect(html).to include("Inclui lavagem.")
  end

  it "renders no description line when none is given" do
    html = described_class.new(service: service, href: "/x").call

    expect(html).not_to include("data-description")
  end

  it "renders the aside the caller passes" do
    html = described_class.new(service: service, href: "/x").call { "R$ 90,00" }

    expect(html).to include("R$ 90,00")
  end
end
