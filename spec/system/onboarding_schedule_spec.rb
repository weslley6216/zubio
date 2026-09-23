require "rails_helper"

RSpec.describe "Onboarding weekday chips and lunch break", type: :system, js: true do
  def sign_up_and_reach_working_hours
    visit new_signup_url(host: Tenant::PLATFORM_HOST)
    fill_in "Seu nome", with: "Ana Lima"
    fill_in "E-mail", with: "ana@example.com"
    fill_in "Senha", with: "s3cr3t123"
    click_on "Criar conta"
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
  end

  it "checks a day chip and tracks the count, then checks the whole week with Todos" do
    sign_up_and_reach_working_hours

    find("label", text: "Ter", exact_text: true).click

    expect(page).to have_content("1 dia selecionado")

    click_on "Todos"

    expect(page).to have_content("7 dias selecionados")
  end

  it "reveals the lunch fields only while the toggle is on, and records nothing while it is off" do
    sign_up_and_reach_working_hours

    expect(page).to have_css("#working_hours_break_starts_at", visible: false)
    expect(page).not_to have_css("#working_hours_break_starts_at", visible: true)

    find("label:has([data-onboarding-target='breakToggle'])").click

    expect(page).to have_css("#working_hours_break_starts_at", visible: true)

    page.execute_script(%(document.getElementById('working_hours_break_starts_at').value = '12:00'))
    page.execute_script(%(document.getElementById('working_hours_break_ends_at').value = '14:00'))
    find("label:has([data-onboarding-target='breakToggle'])").click

    expect(page).not_to have_css("#working_hours_break_starts_at", visible: true)
    expect(find("#working_hours_break_starts_at", visible: :all).value).to eq("")
    expect(find("#working_hours_break_ends_at", visible: :all).value).to eq("")
  end

  it "summarizes the lunch break and keeps it on after resuming the draft" do
    sign_up_and_reach_working_hours
    find("label:has([data-onboarding-target='breakToggle'])").click
    page.execute_script(<<~JS)
      ["working_hours_break_starts_at", "working_hours_break_ends_at"].forEach((id, index) => {
        const field = document.getElementById(id)
        field.value = index === 0 ? "12:00" : "14:00"
        field.dispatchEvent(new Event("input", { bubbles: true }))
      })
    JS

    expect(page).to have_content("12:00 às 14:00")

    page.refresh

    expect(page).to have_content("12:00 às 14:00")
    expect(find("[data-onboarding-target='breakToggle']", visible: :all)).to be_checked
    expect(page).to have_css("#working_hours_break_starts_at", visible: true)
  end
end
