require "rails_helper"

RSpec.describe "Owner working hours", type: :system, js: true do
  %w[light dark].each do |scheme|
    it "renders the weekly screen with legible day chips, in #{scheme}" do
      tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
      owner = create(:user, tenant: tenant)
      professional = create(:professional, tenant: tenant, user: owner)
      ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
      emulate_color_scheme(scheme)
      sign_in_owner(owner)

      visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

      expect(page).to have_css("[data-day='2'] input[name='working_hours[2][active]'][checked]", visible: :all)
      expect(contrast_ratio("[data-day='2'] label")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(contrast_ratio("[data-day='3'] label")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end

  it "paints a marked day's chip and switch apart from an unmarked one" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant)
    professional = create(:professional, tenant: tenant, user: owner)
    ActsAsTenant.with_tenant(tenant) { professional.replace_working_hours!(2 => [ [ "09:00", "18:00" ] ]) }
    emulate_color_scheme("light")
    sign_in_owner(owner)

    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

    expect(computed("[data-day='2'] label", "backgroundColor")).not_to eq(computed("[data-day='3'] label", "backgroundColor"))
    expect(computed("[data-day='2'] label + label", "backgroundColor")).not_to eq(computed("[data-day='3'] label + label", "backgroundColor"))
    expect(computed("[data-day='2'] label + label", "justifyContent")).to eq("flex-end")
    expect(computed("[data-day='3'] label + label", "justifyContent")).to eq("flex-start")
  end

  it "keeps a day's time fields hidden while it is unmarked" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant)
    create(:professional, tenant: tenant, user: owner)
    emulate_color_scheme("light")
    sign_in_owner(owner)

    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

    expect(page).to have_field("working_hours[2][opens_at_0]", visible: :hidden)
  end

  it "reveals a day's time fields once it is marked" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant)
    create(:professional, tenant: tenant, user: owner)
    emulate_color_scheme("light")
    sign_in_owner(owner)
    visit "http://#{tenant.subdomain}.zubio.com.br#{edit_owner_working_hours_path}"

    find("[data-day='2'] label", match: :first).click

    expect(page).to have_field("working_hours[2][opens_at_0]", visible: :visible)
  end
end
