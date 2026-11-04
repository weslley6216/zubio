require "rails_helper"

RSpec.describe "Owner settings colors row", type: :system, js: true do
  it "paints the background and the accent chips on the colors row and fits the phone" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    owner = create(:user, tenant: tenant, email: "ze@example.com", password: "s3cr3t123")
    create(:branding, :with_background, tenant: tenant)
    sign_in_owner(owner)

    visit "http://barbearia-do-ze.zubio.com.br#{owner_settings_path}"

    expect(computed_hex("[data-chip='background']", "backgroundColor")).to eq("#16324A")
    expect(computed_hex("[data-chip='accent']", "backgroundColor")).to eq("#F0617A")
    expect(computed("[data-chip='background']", "width")).to eq("28px")
    expect(computed("[data-chip='background']", "borderTopLeftRadius")).to eq("8px")
    expect(page).to fit_the_phone_width
  end
end
