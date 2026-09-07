require "rails_helper"

RSpec.describe "Application surface", type: :system, js: true do
  def submit_invalid_credentials
    fill_in "E-mail", with: "nobody@example.com"
    fill_in "Senha", with: "wrong-password"
    click_button "Entrar"
  end
  it "keeps the stored dark choice when the visitor moves from the landing to the signup screen" do
    emulate_color_scheme("light")

    visit "http://zubio.com.br/"
    click_button Components::Platform::Header::TOGGLE_LABEL

    visit "http://zubio.com.br#{new_signup_path}"

    expect(page.evaluate_script("document.documentElement.dataset.theme")).to eq("dark")
    expect(computed("html", "backgroundColor")).to eq("rgb(11, 17, 23)")
  end

  it "paints the tenant screens dark when the system asks for dark" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant)

    emulate_color_scheme("dark")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"

    expect(computed("html", "backgroundColor")).to eq("rgb(11, 17, 23)")
  end

  it "paints the tenant screens light when the system asks for light" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant)

    emulate_color_scheme("light")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"

    expect(computed("html", "backgroundColor")).to eq("rgb(244, 246, 248)")
  end

  it "keeps the theme toggle reachable on a phone, where the signup screen has no menu to hide it in" do
    page.driver.resize(375, 667)
    emulate_color_scheme("light")

    visit "http://zubio.com.br#{new_signup_path}"
    click_button Components::Platform::Header::TOGGLE_LABEL

    expect(page.evaluate_script("document.documentElement.dataset.theme")).to eq("dark")
  end

  it "renders the login alert as a band that separates from the panel in the light theme" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant)

    emulate_color_scheme("light")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"
    submit_invalid_credentials

    expect(contrast_ratio("[data-alert]")).to be >= Branding::ColorScale::MIN_CONTRAST
    expect(computed("[data-alert]", "borderTopWidth")).not_to eq("0px")
    expect(computed("[data-alert]", "borderTopColor")).not_to eq(computed("[data-alert]", "color"))
    expect(computed("[data-alert]", "backgroundColor")).not_to eq(computed("[data-panel]", "backgroundColor"))
  end

  it "renders the login alert as a band that separates from the panel in the dark theme" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    create(:branding, tenant: tenant)

    emulate_color_scheme("dark")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"
    submit_invalid_credentials

    expect(contrast_ratio("[data-alert]")).to be >= Branding::ColorScale::MIN_CONTRAST
    expect(computed("[data-alert]", "borderTopWidth")).not_to eq("0px")
    expect(computed("[data-alert]", "borderTopColor")).not_to eq(computed("[data-alert]", "color"))
    expect(computed("[data-alert]", "backgroundColor")).not_to eq(computed("[data-panel]", "backgroundColor"))
  end
end
