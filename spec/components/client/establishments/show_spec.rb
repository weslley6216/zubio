require "rails_helper"

RSpec.describe Views::Client::Establishments::Show, type: :component do
  let(:tenant) { build(:tenant, name: "Barbearia do Zé") }
  let(:branding) { build(:branding, :with_background, tenant: tenant) }
  let(:service) { build(:service, tenant: tenant, name: "Corte", duration_minutes: 40) }

  it "renders the showcase with the themed background and two-column tiled cards" do
    html = render_phlex(described_class.new(tenant: tenant, branding: branding, services: [ service ]))

    expect(html).to include("(--theme-bg)")
    expect(html).to include("grid-cols-2")
    expect(html).to include("(--theme-card)")
  end

  it "keeps the header on the theme background with no brand band" do
    html = render_phlex(described_class.new(tenant: tenant, branding: branding, services: [ service ]))

    expect(html).not_to include("bg-brand")
    expect(html).not_to include("text-on-brand")
  end

  it "shows the empty catalog card on the themed background" do
    html = render_phlex(described_class.new(tenant: tenant, branding: branding, services: []))

    expect(html).to include("Nenhum serviço publicado ainda")
    expect(html).to include("(--theme-card)")
  end

  it "renders the google failure notice as a themed error card above the catalog title" do
    html = render_phlex(described_class.new(tenant: tenant, branding: branding, services: [ service ]), flash: { alert: "Não foi possível entrar com o Google. Tente de novo." })

    expect(html.index("(--theme-danger-on-card)")).to be < html.index("Escolha o serviço")
  end

  it "renders no failure notice when signin did not fail" do
    html = render_phlex(described_class.new(tenant: tenant, branding: branding, services: [ service ]))

    expect(html).not_to include("(--theme-danger-on-card)")
  end

  it "falls back to a neutral page with white cards and an accent button when there is no background" do
    neutral_tenant = build(:tenant, name: "Mary Sombracelhas")
    neutral_branding = build(:branding, tenant: neutral_tenant)

    html = render_phlex(described_class.new(tenant: neutral_tenant, branding: neutral_branding, services: [ service ], my_appointments_count: 2))

    expect(html).to include("(--theme-bg)")
    expect(html).to include("(--theme-accent)")
  end
end
