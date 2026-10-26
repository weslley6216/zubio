require "rails_helper"

RSpec.describe "Owner desktop navigation band", type: :system, js: true do
  it "shows the band with the destinations on the 1280px desktop, without a way out" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, tenant: tenant, brand_600: "#2C6CB0")
    owner = create(:user, :with_professional, tenant: tenant)
    emulate_desktop_screen(width: 1280, height: 900)
    sign_in_owner(owner)

    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_appointments_path}"

    expect(page).to have_css("[data-owner-band]")
    within "[data-owner-band]" do
      expect(page).to have_text("Agenda")
      expect(page).to have_text("Serviços")
      expect(page).to have_text("Horários")
      expect(page).to have_text("Clientes")
      expect(page).to have_text("Configurações")
      expect(page).to have_no_text("Sair")
    end
  end

  %w[light dark].each do |scheme|
    it "renders the band in #{scheme}" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      create(:branding, tenant: tenant, brand_600: "#2C6CB0")
      owner = create(:user, :with_professional, tenant: tenant)
      emulate_color_scheme(scheme)
      emulate_desktop_screen(width: 1280, height: 900)
      sign_in_owner(owner)

      visit "http://#{tenant.subdomain}.zubio.com.br#{owner_appointments_path}"

      expect(page).to have_css("[data-owner-band]")
    end
  end

  it "hides the band on the phone and keeps the menu, without sideways scroll" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, tenant: tenant, brand_600: "#2C6CB0")
    owner = create(:user, :with_professional, tenant: tenant)
    emulate_phone
    sign_in_owner(owner)

    visit "http://#{tenant.subdomain}.zubio.com.br#{owner_appointments_path}"

    expect(page).to have_css("[data-owner-band]", visible: :hidden)
    expect(page).to have_css("summary")
    expect(page).to fit_the_phone_width
  end
end
