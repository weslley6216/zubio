require "rails_helper"

RSpec.describe "Owner service form", type: :system, js: true do
  it "fits the new service form on the phone screen" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    sign_in_owner(create(:user, tenant: tenant))

    visit "http://estudio-aurora.zubio.com.br#{new_owner_service_path}"

    expect(page).to fit_the_phone_width
  end
end
