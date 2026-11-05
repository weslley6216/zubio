require "rails_helper"

RSpec.describe Views::Mailers::Client::BookingReceipt, type: :component do
  it "paints the band and the button with the brand and its contrasting text" do
    tenant = create(:tenant, name: "Barbearia 2K", subdomain: "barbearia-2k")
    branding = build(:branding, tenant: tenant, brand_600: "#B5123E")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 11, 10, 9, 45))

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment))

    expect(html).to include("background:#B5123E")
    expect(html).to include("color:#ffffff")
  end

  it "switches to dark text on a light brand" do
    tenant = create(:tenant, name: "Barbearia 2K", subdomain: "barbearia-2k")
    branding = build(:branding, tenant: tenant, brand_600: "#F2C94C")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 11, 10, 9, 45))

    band = Nokogiri::HTML5(render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment))).at_css("[data-band]").to_html

    expect(band).to include("color:#0e1a24")
    expect(band).not_to include("color:#ffffff")
  end

  it "shows the four details with the screen's texts" do
    tenant = create(:tenant, name: "Barbearia 2K", subdomain: "barbearia-2k")
    branding = build(:branding, tenant: tenant, brand_600: "#B5123E")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 11, 10, 9, 45))

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment))

    expect(html).to include("Quando")
    expect(html).to include("Serviço")
    expect(html).to include("Duração")
    expect(html).to include("Valor")
    expect(html).to include("Ter, 10 nov · 09:45")
    expect(html).to include("Design de sobrancelhas")
    expect(html).to include("45 min · termina 10:30")
    expect(html).to include("R$ 60,00")
    expect(html).to include("Horário confirmado")
    expect(html).to include("A Mary já está sabendo, Ana.")
    expect(Nokogiri::HTML5(html).at_css("html")["lang"]).to eq("pt-BR")
  end

  it "links the button to the appointment on the establishment's host" do
    tenant = create(:tenant, name: "Barbearia 2K", subdomain: "barbearia-2k")
    branding = build(:branding, tenant: tenant, brand_600: "#B5123E")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 11, 10, 9, 45))

    link = Nokogiri::HTML5(render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment))).at_css("a[data-receipt-link]")

    expect(link.text).to eq("Ver ou desmarcar")
    expect(link["href"]).to include("barbearia-2k.zubio.com.br/a/#{appointment.cancel_token}")
  end

  it "follows the verified custom domain" do
    tenant = create(:tenant, :with_verified_custom_domain, name: "Barbearia 2K", subdomain: "barbearia-2k")
    branding = build(:branding, tenant: tenant, brand_600: "#B5123E")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 11, 10, 9, 45))

    html = Nokogiri::HTML5(render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment)))

    expect(html.at_css("a[data-receipt-link]")["href"]).to include("barbeariadoze.com.br/a/")
    expect(html.at_css("a[data-signature-link]").text).to eq("barbeariadoze.com.br")
  end

  it "shows the logo from the establishment's host" do
    tenant = create(:tenant, name: "Barbearia 2K", subdomain: "barbearia-2k")
    branding = create(:branding, :with_logo, tenant: tenant, brand_600: "#B5123E")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 11, 10, 9, 45))

    logos = Nokogiri::HTML5(render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment))).css("img[data-brand-logo]")

    expect(logos.size).to eq(2)
    expect(logos.map { |logo| logo["src"] }).to all(start_with("https://barbearia-2k.zubio.com.br/rails/active_storage/"))
    expect(logos.map { |logo| logo["alt"] }).to all(eq("Barbearia 2K"))
  end

  it "shows the initial when there is no logo" do
    tenant = create(:tenant, name: "Titiko Crochê", subdomain: "titiko-croche")
    branding = build(:branding, tenant: tenant, brand_600: "#B5123E")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 11, 10, 9, 45))

    html = Nokogiri::HTML5(render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment)))

    expect(html.css("img")).to be_empty
    expect(html.css("[data-brand-initial]").map(&:text)).to eq([ "T", "T" ])
  end

  it "signs with the name, the page and the Zubio note" do
    tenant = create(:tenant, name: "Barbearia 2K", subdomain: "barbearia-2k")
    branding = build(:branding, tenant: tenant, brand_600: "#B5123E")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 11, 10, 9, 45))

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment))

    expect(Nokogiri::HTML5(html).at_css("a[data-signature-link]").text).to eq("barbearia-2k.zubio.com.br")
    expect(html).to include("Barbearia 2K")
    expect(html).to include("Agendado pelo Zubio")
  end

  it "escapes what the establishment typed" do
    tenant = create(:tenant, name: "Barbearia 2K", subdomain: "barbearia-2k")
    branding = build(:branding, tenant: tenant, brand_600: "#B5123E")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Corte <b>premium</b>", duration_minutes: 45, price_cents: 6_000)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client,
      starts_at: Time.zone.local(2026, 11, 10, 9, 45))

    html = render_phlex(described_class.new(tenant: tenant, branding: branding, appointment: appointment))

    expect(html).to include("Corte &lt;b&gt;premium&lt;/b&gt;")
  end
end
