require "rails_helper"

RSpec.describe "Owner onboarding submit lock", type: :system, js: true do
  it "locks the final step with Criando sua página…" do
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
    %w[Ter Qua Qui Sex Sáb].each { |weekday| find("label", text: weekday, exact_text: true).click }
    fill_in "working_hours_opens_at", with: "09:00"
    fill_in "working_hours_closes_at", with: "18:00"

    state = submit_lock_state("button[type=submit]", "button.click(); button.click();")

    expect(state["disabled"]).to be(true)
    expect(state["label"]).to eq("Criando sua página…")
  end

  it "does not lock when a middle question is submitted" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"

    state = submit_lock_state("button[type=submit]", 'document.querySelector("form").requestSubmit();')

    expect(state["disabled"]).to be(false)
    expect(state["label"]).to eq("Ver minha página")
  end

  it "still advances after a middle question is submitted" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    page.execute_script('document.querySelector("form").requestSubmit()')

    click_on "Continuar"

    expect(page).to have_content("Nome da marca")
  end

  it "yields to the logo upload message and then stamps the page label" do
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
    %w[Ter Qua Qui Sex Sáb].each { |weekday| find("label", text: weekday, exact_text: true).click }
    fill_in "working_hours_opens_at", with: "09:00"
    fill_in "working_hours_closes_at", with: "18:00"

    result = page.evaluate_script(<<~JS)
      (function() {
        const logo = document.querySelector('[data-controller="logo"]')
        const button = document.querySelector('[data-submit-lock-target="button"]')
        logo.dataset.uploadState = "uploading"
        button.click()
        const duringUpload = { disabled: button.disabled, label: button.textContent }

        delete logo.dataset.uploadState
        logo.dispatchEvent(new CustomEvent("logo:settled", { bubbles: true }))
        const afterSettle = { disabled: button.disabled, label: button.textContent }

        return JSON.stringify({ duringUpload: duringUpload, afterSettle: afterSettle })
      })()
    JS
    state = JSON.parse(result)

    expect(state["duringUpload"]).to eq({ "disabled" => true, "label" => "Enviando a sua logo…" })
    expect(state["afterSettle"]).to eq({ "disabled" => true, "label" => "Criando sua página…" })
    expect(page).to have_content("Sua página está no ar")
  end
end
