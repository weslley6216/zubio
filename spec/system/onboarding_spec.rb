require "rails_helper"

RSpec.describe "Onboarding journey", type: :system, js: true do
  def document_requests
    page.driver.network_traffic.count { |exchange| exchange.request&.type?("document") }
  end

  def sign_up_and_reach_onboarding
    visit new_signup_url(host: Tenant::PLATFORM_HOST)
    fill_in "Seu nome", with: "Ana Lima"
    fill_in "E-mail", with: "ana@example.com"
    fill_in "Senha", with: "s3cr3t123"
    click_on "Criar conta"

    expect(page).to have_content("Vamos montar a sua página de agendamentos").or have_button("Começar")
  end

  it "crosses the five questions with no request between them and one at the end" do
    sign_up_and_reach_onboarding
    click_on "Começar"

    page.driver.clear_network_traffic

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
    %w[2 3 4 5 6].each { |weekday| find("label", text: WorkingHour::WEEKDAY_NAMES[weekday.to_i].first(3), exact_text: true).click }
    page.execute_script(%(document.getElementById('working_hours_opens_at').value = '09:00'))
    page.execute_script(%(document.getElementById('working_hours_closes_at').value = '18:00'))

    expect(document_requests).to eq(0)

    click_on "Ver minha página"

    expect(page).to have_content("Sua página está no ar, Ana")
    expect(page).to have_content("barbearia-do-ze.zubio.com.br")
    expect(page).to have_content("1 serviço")
  end

  it "adds a service through the card and sees it listed above a cleared registration card" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"

    fill_in "Nome", with: "Corte na máquina"
    fill_in "Duração (minutos)", with: "30"
    fill_in "Preço (R$, opcional)", with: "45,00"
    click_on "Adicionar à lista"

    expect(page).to have_css("[data-service-row]", text: "Corte na máquina")
    expect(page).to have_content("30 min · R$ 45,00")
    expect(find_field("Nome", with: "")).to be_present
  end

  it "goes back, changes the colour and keeps the other answers on submit" do
    sign_up_and_reach_onboarding
    click_on "Começar"

    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    find("[data-onboarding-target='back']").click
    find("[data-onboarding-target='back']").click
    all("[data-swatch-row] [data-swatch]")[1].click
    click_on "Continuar"
    click_on "Continuar"

    expect(page).to have_content("Tem uma logo?")
    expect(find_field("Nome da marca", visible: :all).value).to eq("Barbearia do Zé")
  end

  it "resumes where it was left off on the same browser" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"

    page.refresh

    expect(page).to have_content("Tem uma logo?")
    expect(find_field("Nome da marca", visible: :all).value).to eq("Barbearia do Zé")
  end

  it "uploads the logo in the background and attaches it by the end" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    click_on "Continuar"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    %w[2 3].each { |weekday| find("label", text: WorkingHour::WEEKDAY_NAMES[weekday.to_i].first(3), exact_text: true).click }
    page.execute_script(%(document.getElementById('working_hours_opens_at').value = '09:00'))
    page.execute_script(%(document.getElementById('working_hours_closes_at').value = '18:00'))
    click_on "Ver minha página"

    expect(page).to have_content("Sua página está no ar, Ana")
    tenant = Tenant.find_by(subdomain: "barbearia-do-ze")
    expect(ActsAsTenant.with_tenant(tenant) { tenant.branding.logo }).to be_attached
  end
end
