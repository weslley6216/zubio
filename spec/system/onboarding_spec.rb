require "rails_helper"

RSpec.describe "Onboarding journey", type: :system, js: true do
  it "walks the whole journey from signup to the shareable link, across the host swap" do
    visit new_signup_url(host: Tenant::PLATFORM_HOST)
    fill_in "Seu nome", with: "Ana Lima"
    fill_in "E-mail", with: "ana@example.com"
    fill_in "Senha", with: "s3cr3t123"
    click_on "Criar conta"

    expect(page).to have_content("Vamos deixar sua página pronta")
    click_on "Começar"

    expect(page).to have_content("Escolha as cores da sua marca")
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"

    expect(page).to have_content("Qual é o nome da sua marca?")
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"

    expect(page).to have_current_path(%r{\Ahttp://barbearia-do-ze\.zubio\.com\.br}, url: true)
    expect(page).to have_content("Tem uma logo?")
    click_on "Pular por enquanto"

    expect(page).to have_content("Nenhum serviço cadastrado")
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$)", with: "90,00"
    click_on "Cadastrar serviço"

    expect(page).to have_content("Corte")
    click_on "Continuar (1 serviço)"

    expect(page).to have_content("Dias de atendimento")
    %w[2 3 4 5 6].each { |weekday| find("input[type=checkbox][value='#{weekday}']").check }
    page.execute_script(%(document.getElementById('working_hours_opens_at').value = '09:00'))
    page.execute_script(%(document.getElementById('working_hours_closes_at').value = '18:00'))
    click_on "Continuar"

    expect(page).to have_content("Sua página está no ar!")
    expect(page).to have_content("barbearia-do-ze.zubio.com.br")
  end
end
