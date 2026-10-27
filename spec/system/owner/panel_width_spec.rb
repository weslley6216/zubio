require "rails_helper"

RSpec.describe "Owner panel content width", type: :system, js: true do
  it "gives the settings family one width and the panel the wider one" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    sign_in_owner(create(:user, :with_professional, tenant: tenant, name: "Ana Lima"))
    emulate_desktop_screen(width: 1280, height: 900)

    family = [ owner_settings_path, owner_services_path, edit_owner_working_hours_path, owner_schedule_exceptions_path, edit_owner_brand_name_path ]
    widths = family.map do |path|
      visit "http://estudio-aurora.zubio.com.br#{path}"
      page.evaluate_script("getComputedStyle(document.querySelector('main')).maxWidth")
    end
    visit "http://estudio-aurora.zubio.com.br#{owner_appointments_path}"
    panel_width = page.evaluate_script("getComputedStyle(document.querySelector('main')).maxWidth")

    expect(widths).to all(eq("1120px"))
    expect(panel_width).to eq("1200px")
  end
end
