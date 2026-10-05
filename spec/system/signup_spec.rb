require "rails_helper"

RSpec.describe "Signup", type: :system, js: true do
  it "keeps the typed password hidden" do
    visit new_signup_url(host: Tenant::PLATFORM_HOST)

    fill_in "Senha", with: "s3cr3t123"

    expect(find_field("Senha")[:type]).to eq("password")
  end

  it "shows the typed password when the visitor asks for it" do
    visit new_signup_url(host: Tenant::PLATFORM_HOST)
    fill_in "Senha", with: "s3cr3t123"

    click_on "Mostrar senha"

    expect(find_field("Senha")[:type]).to eq("text")
  end

  it "creates the account from a name, an email and a password and opens the onboarding" do
    visit new_signup_url(host: Tenant::PLATFORM_HOST)
    fill_in "Seu nome", with: "Ana Lima"
    fill_in "E-mail", with: "ana@example.com"
    fill_in "Senha", with: "s3cr3t123"

    click_on "Criar conta"

    expect(page).to have_content("Vamos montar a sua página de agendamentos")
  end
end
