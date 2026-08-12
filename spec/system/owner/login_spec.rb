require "rails_helper"

RSpec.describe "Owner login", type: :system do
  it "logs the owner in and redirects to the dashboard" do
    tenant = create(:tenant, subdomain: "joes-barbershop")
    owner = create(:user, tenant: tenant, email: "owner@example.com", password: "s3cr3t123")

    visit "http://#{tenant.subdomain}.zubio.com.br#{new_owner_session_path}"
    fill_in "E-mail", with: owner.email
    fill_in "Senha", with: "s3cr3t123"
    click_on "Entrar"

    expect(page).to have_content("Painel")
  end
end
