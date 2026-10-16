require "rails_helper"

RSpec.describe "Owner schedule exceptions", type: :system, js: true do
  it "fits the exceptions screen on the phone screen" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    owner = create(:user, tenant: tenant)
    create(:professional, tenant: tenant, user: owner)
    sign_in_owner(owner)

    visit "http://estudio-aurora.zubio.com.br#{owner_schedule_exceptions_path}"

    expect(page).to fit_the_phone_width
  end
end
