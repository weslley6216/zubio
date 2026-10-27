require "rails_helper"

RSpec.describe "Owner services catalog", type: :system, js: true do
  it "sets the new service action on the title line, right of it, as a 44px touch target" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:service, tenant: tenant, name: "Design de sobrancelhas")
    emulate_phone
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

    title = page.evaluate_script("document.querySelector('main h1').getBoundingClientRect().toJSON()")
    action = page.evaluate_script("document.querySelector('main h1 + a').getBoundingClientRect().toJSON()")
    expect(action["left"]).to be >= title["right"]
    expect(action["top"] + (action["height"] / 2)).to be_between(title["top"], title["bottom"])
    expect(action["height"]).to be >= 44
    expect(page).to fit_the_phone_width
  end

  it "opens the new service form when the owner taps the new action" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:service, tenant: tenant, name: "Design de sobrancelhas")
    emulate_phone
    sign_in_owner(create(:user, tenant: tenant))
    visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

    find("main h1 + a").click

    expect(page).to have_current_path(new_owner_service_path)
  end

  %w[light dark].each do |scheme|
    it "paints the price pill in the light pair of the brand, in #{scheme}" do
      tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
      branding = create(:branding, tenant: tenant, brand_600: "#8E4B6B")
      create(:service, tenant: tenant, name: "Design de sobrancelhas", price_cents: 6_000)
      emulate_phone
      emulate_color_scheme(scheme)
      sign_in_owner(create(:user, tenant: tenant))

      visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

      expect(computed_hex("[data-price]", "backgroundColor")).to eq(branding.css_variables[/--brand-soft-#{scheme}:(#\h{6});/, 1].upcase)
      expect(computed_hex("[data-price]", "color")).to eq(branding.css_variables[/--brand-soft-ink-#{scheme}:(#\h{6});/, 1].upcase)
    end
  end

  it "draws a disabled service on a dashed, faded card and an active one on a solid white card" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:service, tenant: tenant, name: "Design de sobrancelhas")
    create(:service, tenant: tenant, name: "Micropigmentação", active: false)
    emulate_phone
    emulate_color_scheme("light")
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

    expect(computed("[data-catalog] li:nth-child(1)", "borderTopStyle")).to eq("solid")
    expect(computed_hex("[data-catalog] li:nth-child(1)", "backgroundColor")).to eq("#FFFFFF")
    expect(computed("[data-catalog] li:nth-child(2)", "borderTopStyle")).to eq("dashed")
    expect(computed_hex("[data-catalog] li:nth-child(2)", "backgroundColor")).to eq("#F8FAFB")
  end

  it "fits a long disabled service with both badges and a five-digit price on the narrowest phone" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:service, :price_hidden, tenant: tenant, name: "Micropigmentação fio a fio com retoque incluso",
      description: "Medição, limpeza, desenho, pigmentação e retoque em trinta dias", duration_minutes: 180,
      price_cents: 1_000_000, active: false)
    emulate_phone(width: 320, height: 800)
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

    expect(page).to have_text("R$ 10.000,00")
    expect(page).to fit_the_phone_width
  end

  it "shows the table on the desktop and hides the cards" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:service, tenant: tenant, name: "Design de sobrancelhas", price_cents: 6_000)
    emulate_desktop_screen(width: 1280)
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

    expect(page).to have_css("[data-service-table]", visible: :visible)
    expect(page).to have_css("[data-catalog]", visible: :hidden)
  end

  it "shows the cards on the phone and hides the table, without sideways scroll" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:service, tenant: tenant, name: "Design de sobrancelhas", price_cents: 6_000)
    emulate_phone
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

    expect(page).to have_css("[data-catalog]", visible: :visible)
    expect(page).to have_css("[data-service-table]", visible: :hidden)
    expect(page).to fit_the_phone_width
  end

  %w[light dark].each do |scheme|
    it "paints the active situation pill in the brand soft pair on the desktop, in #{scheme}" do
      tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
      branding = create(:branding, tenant: tenant, brand_600: "#8E4B6B")
      create(:service, tenant: tenant, name: "Design de sobrancelhas", price_cents: 6_000)
      emulate_color_scheme(scheme)
      emulate_desktop_screen(width: 1280)
      sign_in_owner(create(:user, tenant: tenant))

      visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

      expect(computed_hex("[data-service-table] [data-status]", "backgroundColor")).to eq(branding.css_variables[/--brand-soft-#{scheme}:(#\h{6});/, 1].upcase)
      expect(computed_hex("[data-service-table] [data-status]", "color")).to eq(branding.css_variables[/--brand-soft-ink-#{scheme}:(#\h{6});/, 1].upcase)
    end
  end

  it "leaves the way back to settings to the band on the desktop" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:service, tenant: tenant, name: "Design de sobrancelhas")
    emulate_desktop_screen(width: 1280)
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

    expect(page).to have_css("main a[href='#{owner_settings_path}']", visible: :hidden)
  end

  it "keeps the way back to settings above the title on the phone" do
    tenant = create(:tenant, subdomain: "mary-sombracelhas", name: "Mary Sombracelhas")
    create(:service, tenant: tenant, name: "Design de sobrancelhas")
    emulate_phone
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://mary-sombracelhas.zubio.com.br#{owner_services_path}"

    expect(page).to have_css("main a[href='#{owner_settings_path}']", visible: :visible)
  end
end
