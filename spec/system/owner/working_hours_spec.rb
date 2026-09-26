require "rails_helper"

RSpec.describe "Owner working hours", type: :system, js: true do
  it "renders the weekly screen in both color schemes with legible day chips" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    professional = ActsAsTenant.with_tenant(tenant) { create(:professional, tenant: tenant, user: owner) }
    ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }

    %w[light dark].each do |scheme|
      emulate_color_scheme(scheme)
      sign_in_owner(tenant, owner)
      visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

      expect(page).to have_css("[data-day='2'] input[name='working_hours[2][active]'][checked]", visible: :all)
      expect(contrast_ratio("[data-day='2']")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end

  it "reveals a day's time fields only when it is marked" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")
    ActsAsTenant.with_tenant(tenant) { create(:professional, tenant: tenant, user: owner) }

    emulate_color_scheme("light")
    sign_in_owner(tenant, owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

    expect(page).to have_field("working_hours[2][opens_at_0]", visible: :hidden)

    find("[data-day='2'] label", match: :first).click

    expect(page).to have_field("working_hours[2][opens_at_0]", visible: :visible)
  end
end
