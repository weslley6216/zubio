require "rails_helper"

RSpec.describe "Signup", type: :system, js: true do
  it "asks for name, email and password, toggles the password's visibility, and creates the account" do
    visit new_signup_url(host: Tenant::PLATFORM_HOST)

    fill_in "Seu nome", with: "Ana Lima"
    fill_in "E-mail", with: "ana@example.com"
    fill_in "Senha", with: "s3cr3t123"
    expect(find_field("Senha")[:type]).to eq("password")

    click_on "Mostrar senha"

    expect(find_field("Senha")[:type]).to eq("text")

    click_on "Criar conta"

    expect(page).to have_content("Vamos deixar sua página pronta")
  end
end
