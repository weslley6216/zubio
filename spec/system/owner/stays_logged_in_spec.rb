require "rails_helper"

RSpec.describe "Owner stays logged in", type: :system, js: true do
  it "keeps the owner logged in after the app is closed and reopened" do
    tenant = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    create(:branding, tenant: tenant)
    owner = create(:user, :with_professional, tenant: tenant, name: "Zé")
    sign_in_owner(owner)

    discard_session_cookies
    visit owner_appointments_url(host: "#{tenant.subdomain}.zubio.com.br")

    expect(page).to have_no_current_path(new_owner_session_path, ignore_query: true)
    expect(page).to have_css("[data-day]")
  end
end
