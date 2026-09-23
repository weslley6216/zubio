require "rails_helper"

RSpec.describe "Onboarding viewport", type: :system, js: true do
  def sign_up_and_reach_onboarding
    visit new_signup_url(host: Tenant::PLATFORM_HOST)
    fill_in "Seu nome", with: "Ana Lima"
    fill_in "E-mail", with: "ana@example.com"
    fill_in "Senha", with: "s3cr3t123"
    click_on "Criar conta"
  end

  def taller_than_screen?
    page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
  end

  def scroll_width = page.evaluate_script("document.documentElement.scrollWidth")

  def no_floating_card? = !page.has_css?("[data-panel]", visible: :all)

  %w[light dark].each do |scheme|
    it "fits every one of the seven screens inside a 390x800 phone, in #{scheme}" do
      page.driver.resize(390, 800)
      emulate_color_scheme(scheme)
      sign_up_and_reach_onboarding

      expect(taller_than_screen?).to be(false)
      expect(scroll_width).to eq(390)
      expect(no_floating_card?).to be(true)
      expect(page).to have_button("Começar")

      click_on "Começar"
      expect(taller_than_screen?).to be(false)
      expect(page).to have_button("Continuar")

      find("[data-swatch-row] [data-swatch]", match: :first).click
      click_on "Continuar"
      expect(taller_than_screen?).to be(false)

      fill_in "Nome da marca", with: "Barbearia do Zé"
      click_on "Continuar"
      expect(taller_than_screen?).to be(false)

      click_on "Pular por enquanto"
      expect(taller_than_screen?).to be(false)

      fill_in "Nome", with: "Corte"
      fill_in "Duração (minutos)", with: "45"
      fill_in "Preço (R$, opcional)", with: "90,00"
      click_on "Adicionar à lista"
      click_on "Continuar com 1 serviço"
      expect(taller_than_screen?).to be(false)

      %w[Ter Qua Qui Sex Sáb].each { |label| find("label", text: label, exact_text: true).click }
      page.execute_script(%(document.getElementById('working_hours_opens_at').value = '09:00'))
      page.execute_script(%(document.getElementById('working_hours_closes_at').value = '18:00'))

      click_on "Ver minha página"
      expect(taller_than_screen?).to be(false)
      expect(no_floating_card?).to be(true)
    end
  end
end
