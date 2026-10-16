require "rails_helper"

RSpec.describe "Onboarding service duration parity", type: :system, js: true do
  it "builds the client label with the same spacing the server renders after a refusal" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte + barba"
    fill_in "Duração (minutos)", with: "90"
    fill_in "Preço (R$, opcional)", with: "80"
    click_on "Adicionar à lista"

    expect(find("[data-service-meta]", visible: :all).text(:all)).to eq("1 h 30 min · R$ 80,00")

    click_on "Continuar com 1 serviço"
    find("label", text: "Ter", exact_text: true).click
    fill_in "working_hours_opens_at", with: "18:00"
    fill_in "working_hours_closes_at", with: "09:00"
    click_on "Ver minha página"

    expect(page).to have_content(Owner::OnboardingController::REFUSED)
    expect(find("[data-service-meta]", visible: :all).text(:all)).to eq("1 h 30 min · R$ 80,00")
  end
end
