require "rails_helper"

RSpec.describe "Owner phone menu", type: :system, js: true do
  it "dims the page behind the open menu and leaves the header bright" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, tenant: tenant, brand_600: "#2C6CB0")
    sign_in_owner(create(:user, tenant: tenant, name: "José Souza"))

    find("summary", text: Components::Owner::Menu::LABEL, visible: :all).click

    expect(page).to have_css("details[open]")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('main')).opacity")).to eq("0.45")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('header')).opacity")).to eq("1")
  end

  it "keeps the page at full strength while the menu is closed" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, tenant: tenant, brand_600: "#2C6CB0")
    sign_in_owner(create(:user, tenant: tenant, name: "José Souza"))

    expect(page).to have_css("details:not([open])", visible: :all)
    expect(page.evaluate_script("getComputedStyle(document.querySelector('main')).opacity")).to eq("1")
  end
end
