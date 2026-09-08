require "rails_helper"

RSpec.describe "Signup subdomain field", type: :system, js: true do
  it "derives the address from the establishment name and reports it free" do
    visit new_signup_url(host: Tenant::PLATFORM_HOST)

    fill_in "Nome do estabelecimento", with: "Estúdio Aurora"

    expect(page).to have_field("Subdomínio", with: "estudio-aurora")
    expect(page).to have_content("estudio-aurora.zubio.com.br está disponível")
  end

  it "stops deriving the subdomain once the visitor edits it themselves" do
    visit new_signup_url(host: Tenant::PLATFORM_HOST)
    fill_in "Nome do estabelecimento", with: "Estúdio Aurora"
    fill_in "Subdomínio", with: "aurora"

    fill_in "Nome do estabelecimento", with: "Estúdio Aurora Centro"

    expect(page).to have_field("Subdomínio", with: "aurora")
  end
end
