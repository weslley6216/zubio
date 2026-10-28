require "rails_helper"

RSpec.describe "Owner clients screen", type: :system, js: true do
  %w[light dark].each do |scheme|
    it "fits the phone width in #{scheme}" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
      create(:branding, tenant: tenant)
      owner = create(:user, :with_professional, tenant: tenant)
      client = create(:client, tenant: tenant, name: "Camila Nunes")
      ActsAsTenant.with_tenant(tenant) { create(:appointment, :completed, tenant: tenant, client: client, starts_at: Time.zone.local(2026, 8, 22, 10, 0)) }
      emulate_color_scheme(scheme)
      sign_in_owner(owner)

      visit "http://#{tenant.subdomain}.zubio.com.br#{owner_clients_path}"

      expect(page).to have_text("Suas clientes")
      expect(page).to fit_the_phone_width
    end
  end

  it "shows the table columns on the 1280px desktop" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant)
    owner = create(:user, :with_professional, tenant: tenant)
    client = create(:client, tenant: tenant, name: "Camila Nunes")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, :completed, tenant: tenant, client: client, starts_at: 1.week.ago) }
    emulate_desktop_screen(width: 1280, height: 900)
    sign_in_owner(owner)

    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_clients_path}"

    expect(page).to have_text("CELULAR").and have_text("VISITAS")
  end

  it "filters the list as the owner types" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant)
    owner = create(:user, :with_professional, tenant: tenant)
    create(:client, tenant: tenant, name: "Camila Nunes")
    create(:client, tenant: tenant, name: "Bruna Salles")
    emulate_phone
    sign_in_owner(owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_clients_path}"

    fill_in "Nome ou telefone", with: "camila"

    expect(page).to have_text("Camila Nunes")
    expect(page).to have_no_text("Bruna Salles")
  end

  it "shows the list at full strength while the frame is idle" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    owner = create(:user, :with_professional, tenant: tenant)
    create(:client, tenant: tenant, name: "Camila Nunes")
    sign_in_owner(owner)

    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_clients_path}"

    expect(computed("[data-busy-fade]", "opacity")).to eq("1")
    expect(computed("[data-busy-fade]", "pointerEvents")).to eq("auto")
  end

  it "fades the list while the frame reloads" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    owner = create(:user, :with_professional, tenant: tenant)
    create(:client, tenant: tenant, name: "Camila Nunes")
    sign_in_owner(owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_clients_path}"

    page.execute_script("document.getElementById('clients').setAttribute('busy', '')")

    expect(computed("[data-busy-fade]", "opacity")).to eq("0.5")
    expect(computed("[data-busy-fade]", "pointerEvents")).to eq("none")
  end

  it "moves the focus ring from the search input to the search box border" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    owner = create(:user, :with_professional, tenant: tenant)
    sign_in_owner(owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_clients_path}"

    find("input[name=q]").click

    expect(computed("input[name=q]", "outlineStyle")).to eq("none")
    expect(computed_hex("form:has(> input[name=q])", "borderTopColor")).to eq("#8E4B6B")
  end
end
