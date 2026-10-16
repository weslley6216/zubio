require "rails_helper"

RSpec.describe "Owner working hours", type: :system, js: true do
  %w[light dark].each do |scheme|
    it "renders an open day with its name and a legible toggle, in #{scheme}" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      owner = create(:user, tenant: tenant)
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      emulate_color_scheme(scheme)
      sign_in_owner(owner)

      visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

      expect(page).to have_css("[data-day='2'] input[name='working_hours[2][active]'][checked]", visible: :all)
      expect(page).to have_text("Terça")
      expect(contrast_ratio("[data-day='2'] span")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(page).to fit_the_phone_width
    end
  end

  it "reveals the break fields on + Intervalo and drops them on −" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant)
    professional = create(:professional, tenant: tenant, user: owner)
    ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(3 => [ [ "09:00", "18:00" ] ]) }
    sign_in_owner(owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

    find("[data-day='3'] [data-add-break]").click

    expect(page).to have_field("working_hours[3][break_starts_at]", visible: :visible)

    within("[data-day='3']") { find("button[aria-label='Tirar o intervalo']").click }
    find("[data-day='3'] [name='working_hours[3][closes_at]']")
    click_button Views::Owner::WorkingHours::Edit::SUBMIT_LABEL

    expect(page).to have_text(Owner::WorkingHoursController::SAVED)
    expect(ActsAsTenant.with_tenant(tenant) { professional.working_hours.ordered.count }).to eq(1)
  end

  it "copies the expediente and break to the open days and leaves the closed ones shut" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant)
    professional = create(:professional, tenant: tenant, user: owner)
    ActsAsTenant.with_tenant(tenant) do
      professional.replace_working_hours!(2 => [ [ "09:00", "12:00" ], [ "13:00", "18:00" ] ], 3 => [ [ "10:00", "16:00" ] ])
    end
    sign_in_owner(owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

    find("[data-day='2'] [data-copy]").click
    click_button Views::Owner::WorkingHours::Edit::SUBMIT_LABEL

    expect(page).to have_text(Owner::WorkingHoursController::SAVED)
    wednesday = ActsAsTenant.with_tenant(tenant) { professional.working_hours.for_weekday(3).ordered.to_a }.map { |working_hour| [ working_hour.opens_at.strftime("%H:%M"), working_hour.closes_at.strftime("%H:%M") ] }
    expect(wednesday).to eq([ [ "09:00", "12:00" ], [ "13:00", "18:00" ] ])
    expect(ActsAsTenant.with_tenant(tenant) { professional.working_hours.for_weekday(0).count }).to eq(0)
  end

  it "reopens a grouped closed day through the details and saves its hours" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant)
    professional = create(:professional, tenant: tenant, user: owner)
    ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
    sign_in_owner(owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

    find("[data-closed-days] summary").click
    find("[data-day='0'] label").click
    click_button Views::Owner::WorkingHours::Edit::SUBMIT_LABEL

    expect(page).to have_text(Owner::WorkingHoursController::SAVED)
    expect(ActsAsTenant.with_tenant(tenant) { professional.working_hours.for_weekday(0).count }).to eq(1)
  end

  it "keeps the day controls tall enough to tap on a phone" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant)
    professional = create(:professional, tenant: tenant, user: owner)
    ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "12:00" ], [ "13:00", "18:00" ] ], 3 => [ [ "09:00", "18:00" ] ]) }
    sign_in_owner(owner)

    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

    expect(page.evaluate_script("document.querySelector(\"[data-day='3'] [data-add-break]\").getBoundingClientRect().height")).to be >= 40
    expect(page.evaluate_script("document.querySelector(\"[data-day='2'] button[aria-label='Tirar o intervalo']\").getBoundingClientRect().height")).to be >= 44
    expect(page.evaluate_script("document.querySelector(\"[data-day='2'] label\").getBoundingClientRect().height")).to be >= 26
    expect(page).to fit_the_phone_width
  end
end
