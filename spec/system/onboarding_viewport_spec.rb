require "rails_helper"

RSpec.describe "Onboarding viewport", type: :system, js: true do
  %w[light dark].each do |scheme|
    it "fits every one of the seven screens inside a 390x800 phone, with no floating card, in #{scheme}" do
      owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
      page.driver.resize(390, 800)
      emulate_color_scheme(scheme)
      sign_in_owner(owner)
      taller_than_screen = {}
      scroll_width = {}
      without_floating_card = {}

      find_button("Começar")
      taller_than_screen["welcome"] = page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
      scroll_width["welcome"] = page.evaluate_script("document.documentElement.scrollWidth")
      without_floating_card["welcome"] = page.has_no_css?("[data-panel]", visible: :all)
      click_on "Começar"
      find_button("Continuar")
      taller_than_screen["colors"] = page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
      find("[data-swatch-row] [data-swatch]", match: :first).click
      click_on "Continuar"
      taller_than_screen["name"] = page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
      fill_in "Nome da marca", with: "Barbearia do Zé"
      click_on "Continuar"
      taller_than_screen["logo"] = page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
      click_on "Pular por enquanto"
      taller_than_screen["services"] = page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
      fill_in "Nome", with: "Corte"
      fill_in "Duração (minutos)", with: "45"
      fill_in "Preço (R$, opcional)", with: "90,00"
      click_on "Adicionar à lista"
      click_on "Continuar com 1 serviço"
      taller_than_screen["working_hours"] = page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
      %w[Ter Qua Qui Sex Sáb].each { |weekday| find("label", text: weekday, exact_text: true).click }
      fill_in "working_hours_opens_at", with: "09:00"
      fill_in "working_hours_closes_at", with: "18:00"
      click_on "Ver minha página"
      find("body", text: "Sua página está no ar")
      taller_than_screen["final"] = page.evaluate_script("document.documentElement.scrollHeight > window.innerHeight")
      scroll_width["final"] = page.evaluate_script("document.documentElement.scrollWidth")
      without_floating_card["final"] = page.has_no_css?("[data-panel]", visible: :all)

      expect(taller_than_screen).to eq(
        "welcome" => false, "colors" => false, "name" => false, "logo" => false,
        "services" => false, "working_hours" => false, "final" => false
      )
      expect(scroll_width).to eq("welcome" => 390, "final" => 390)
      expect(without_floating_card).to eq("welcome" => true, "final" => true)
    end
  end
end
