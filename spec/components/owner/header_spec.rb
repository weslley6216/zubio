require "rails_helper"

RSpec.describe Components::Owner::Header, type: :component do
  let(:tenant) { build(:tenant, name: "Mary Sombracelhas") }
  let(:branding) { build(:branding, tenant: tenant) }

  it "lists the desktop destinations in order and marks the current one" do
    html = render_phlex(described_class.new(tenant: tenant, branding: branding, current_section: :services))

    document = Nokogiri::HTML5.fragment(html)
    band_links = document.css("[data-owner-band] nav a")
    expect(band_links.map(&:text)).to eq(%w[Agenda Serviços Horários Clientes])
    services_tab = document.at_css("[data-owner-band] nav a[href='/owner/services']")
    expect(services_tab["aria-current"]).to eq("page")
    expect(services_tab["class"]).to eq("#{Components::Owner::Header::TAB_CLASS} #{Components::Owner::Header::TAB_CURRENT_CLASS}")
    pill = document.at_css("[data-owner-band] a[href='/owner/settings']")
    expect(pill.at_css("circle[cx='12']")).to be_present
    expect(pill.text).to include(Components::Owner::Header::SETTINGS_LABEL)
  end

  it "marks nothing when the section is not in the band" do
    html = render_phlex(described_class.new(tenant: tenant, branding: branding, current_section: :none))

    document = Nokogiri::HTML5.fragment(html)
    expect(document.css("[data-owner-band] a[aria-current='page']")).to be_empty
  end

  it "keeps serviços and horários out of the phone menu" do
    html = render_phlex(described_class.new(tenant: tenant, branding: branding, current_section: :clients))

    document = Nokogiri::HTML5.fragment(html)
    menu_links = document.css("details a")
    expect(menu_links.map { |link| link["href"] }).to contain_exactly("/owner/clients", "/owner/settings")
  end

  it "carries the theme toggle in the band" do
    html = render_phlex(described_class.new(tenant: tenant, branding: branding, current_section: :services))

    document = Nokogiri::HTML5.fragment(html)
    expect(document.at_css("[data-owner-band] [data-action='theme#toggle']")).to be_present
  end
end
