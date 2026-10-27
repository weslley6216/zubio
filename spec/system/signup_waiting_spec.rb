require "rails_helper"

RSpec.describe "Signup submit lock", type: :system, js: true do
  it "locks the sign-up button with Criando sua página…" do
    visit new_signup_url(host: Tenant::PLATFORM_HOST)
    fill_in "Seu nome", with: "Ana Lima"
    fill_in "E-mail", with: "ana@example.com"
    fill_in "Senha", with: "s3cr3t123"

    state = submit_lock_state("input[type=submit]", "button.click(); button.click();")

    expect(state["disabled"]).to be(true)
    expect(state["label"]).to eq("Criando sua página…")
  end
end
