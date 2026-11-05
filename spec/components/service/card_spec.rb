require "rails_helper"

RSpec.describe Components::Service::Card, type: :component do
  let(:tenant) { build(:tenant) }
  let(:service) { build(:service, tenant: tenant, name: "Corte feminino", duration_minutes: 45) }

  it "renders the name as a link to the given target, with the duration" do
    html = described_class.new(service: service, href: "/services/1/booking/new").call

    expect(html).to include(%(<a href="/services/1/booking/new" class="#{described_class::NAME_CLASS}">Corte feminino</a>))
    expect(html).to include("45 min")
  end

  it "renders every badge given beside the name" do
    disabled = Components::Badge.new(text: "Desativado", tone: :muted)
    hidden_price = Components::Badge.new(text: "Preço oculto", tone: :muted)

    html = described_class.new(service: service, href: "/x", badges: [ disabled, hidden_price ]).call

    expect(html).to include("Desativado")
    expect(html).to include("Preço oculto")
    expect(html).to include(%(<div class="#{described_class::NAME_ROW_CLASS}"><a href="/x"))
  end

  it "renders no badge when the list is empty" do
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

  it "places the name straight in the identity column when there is no badge" do
    html = described_class.new(service: service, href: "/x").call

    expect(html).to include(%(<div class="#{described_class::IDENTITY_CLASS}"><a href="/x"))
    expect(html).not_to include(described_class::NAME_ROW_CLASS)
  end

  it "renders the panel variant's duration in minutes with a clock icon" do
    long_service = build(:service, tenant: tenant, name: "Micropigmentação", duration_minutes: 120)

    html = described_class.new(service: long_service, href: "/x").call

    expect(html).to include(%(<span class="#{described_class::DURATION_CLASS}">120 min</span>))
    expect(html).to include(%(data-icon="clock"))
  end

  it "renders no chevron icon in the panel variant" do
    html = described_class.new(service: service, href: "/x").call

    expect(html).not_to include(%(data-icon="chevron-right"))
  end

  it "renders an active service on a solid card with its name in ink" do
    html = described_class.new(service: service, href: "/x").call

    expect(html).to include(%(<li class="#{described_class::CARD_CLASS}">))
    expect(html).to include(%(<a href="/x" class="#{described_class::NAME_CLASS}">Corte feminino</a>))
    expect(html).to include(%(<span class="#{described_class::DURATION_CLASS}">45 min</span>))
  end

  it "renders a disabled service on a dashed card with its name and duration faded" do
    disabled_service = build(:service, tenant: tenant, name: "Micropigmentação", duration_minutes: 120, active: false)

    html = described_class.new(service: disabled_service, href: "/x").call

    expect(html).to include(%(<li class="#{described_class::DISABLED_CARD_CLASS}">))
    expect(html).to include(%(<a href="/x" class="#{described_class::DISABLED_NAME_CLASS}">Micropigmentação</a>))
    expect(html).to include(%(<span class="#{described_class::DISABLED_DURATION_CLASS}">120 min</span>))
  end

  it "renders the description with the same class in both variants" do
    tile = described_class.new(service: service, href: "/x", variant: :tile, description: "Inclui lavagem.").call
    panel = described_class.new(service: service, href: "/x", description: "Inclui lavagem.").call

    expect(tile).to include(%(<span class="#{described_class::DESCRIPTION_CLASS}" data-description>))
    expect(panel).to include(%(<span class="#{described_class::DESCRIPTION_CLASS}" data-description>))
  end

  it "renders the tile variant's name and duration in minutes without a clock icon" do
    html = described_class.new(service: service, href: "/x", variant: :tile).call

    expect(html).to include(%(<a href="/x" class="#{described_class::TILE_NAME_CLASS}">Corte feminino</a>))
    expect(html).to include("45 min")
    expect(html).not_to include(%(data-icon="clock"))
  end

  it "renders the description in the tile variant too" do
    html = described_class.new(service: service, href: "/x", variant: :tile, description: "Inclui lavagem.").call

    expect(html).to include("data-description")
    expect(html).to include("Inclui lavagem.")
  end

  it "renders the caller's aside beside the duration in the tile variant" do
    html = described_class.new(service: service, href: "/x", variant: :tile).call { "R$ 90" }

    expect(html).to include("R$ 90")
  end

  it "paints the tile variant with theme-aware tokens only" do
    html = described_class.new(service: service, href: "/x", variant: :tile).call

    expect(html).to include("(--theme-card)")
    expect(html).to include("(--theme-on-card)")
    expect(html).not_to include("bg-surface")
    expect(html).not_to include("text-ink")
  end
end
