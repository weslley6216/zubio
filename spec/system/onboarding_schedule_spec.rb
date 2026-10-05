require "rails_helper"

RSpec.describe "Onboarding weekday chips and lunch break", type: :system, js: true do
  it "counts a checked day chip" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"

    find("label", text: "Ter", exact_text: true).click

    expect(page).to have_content("1 dia selecionado")
  end

  it "checks the whole week with Todos" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    find("label", text: "Ter", exact_text: true).click

    click_on "Todos"

    expect(page).to have_content("7 dias selecionados")
  end

  it "fills 12:00 às 14:00 and shows only the summary when the toggle turns on" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"

    find("label:has([data-onboarding-target='breakToggle'])").click

    expect(page).to have_content("12:00 às 14:00")
    expect(page).not_to have_css("#working_hours_break_starts_at", visible: true)
  end

  it "reveals the two lunch fields when the summary is tapped" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    find("label:has([data-onboarding-target='breakToggle'])").click

    find("[data-onboarding-target='breakSummary']").click

    expect(page).to have_css("#working_hours_break_starts_at", visible: true)
    expect(page).to have_css("#working_hours_break_ends_at", visible: true)
  end

  it "clears the lunch and hides the summary when the toggle turns off" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    find("label:has([data-onboarding-target='breakToggle'])").click
    find("[data-onboarding-target='breakSummary']", text: "12:00 às 14:00")

    find("label:has([data-onboarding-target='breakToggle'])").click

    expect(page).not_to have_content("12:00 às 14:00")
    expect(find("#working_hours_break_starts_at", visible: :all).value).to eq("")
    expect(find("#working_hours_break_ends_at", visible: :all).value).to eq("")
  end

  it "keeps the lunch collapsed to its summary after resuming the draft" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    find("label:has([data-onboarding-target='breakToggle'])").click
    find("[data-onboarding-target='breakSummary']", text: "12:00 às 14:00")

    page.refresh

    expect(page).to have_content("12:00 às 14:00")
    expect(find("[data-onboarding-target='breakToggle']", visible: :all)).to be_checked
    expect(page).not_to have_css("#working_hours_break_starts_at", visible: true)
  end
end
