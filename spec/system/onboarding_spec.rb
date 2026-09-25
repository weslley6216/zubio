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

  def direct_upload_requests
    page.driver.network_traffic.count { |exchange| exchange.url&.include?("/rails/active_storage/direct_uploads") }
  end

  def reach_logo_question
    sign_up_and_reach_onboarding
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
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

  it "paints the brand initial into the emblems as the name is typed" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"

    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"

    expect(page).to have_content("Tem uma logo?")
    expect(page).to have_css("[data-onboarding-section='logo'] [data-brand-initial]", text: "B", exact_text: true)
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
    other = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: other)
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
    expect(page).to have_no_content(Views::Owner::Onboarding::Final::LOGO_NOTICE)
    expect(page).to have_css("main img")
    ze = Tenant.find_by(subdomain: "barbearia-do-ze")
    expect(ActsAsTenant.with_tenant(ze) { ze.branding.logo }).to be_attached
    expect(ActsAsTenant.with_tenant(other) { other.branding.logo }).not_to be_attached
  end

  it "shows the chosen image as a preview, drops the 'no logo' card and fills the signed id" do
    reach_logo_question

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))

    expect(page).to have_css("[data-onboarding-section='logo'] img[data-logo-target='preview']:not([hidden])")
    expect(page).to have_no_content(Components::Owner::BrandQuestion::Logo::NO_LOGO_TEXT)
    expect(page).to have_css("[data-logo-target='signedId']", visible: :all)
    expect(find("[data-logo-target='signedId']", visible: :all).value).to be_present
  end

  it "reports the upload state while it settles" do
    reach_logo_question

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))

    expect(page).to have_content("Logo enviada")
    expect(page).to have_css("[data-upload-state='done']")
  end

  it "keeps waiting for a pending upload before leaving the page" do
    reach_logo_question
    held = nil
    page.driver.browser.on(:request) { |request| held = request }
    page.driver.browser.network.intercept(pattern: "*direct_uploads*")

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    expect(page).to have_css("[data-upload-state='uploading']")
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

    expect(page).to have_no_content("Sua página está no ar")
    expect(page).to have_css("[data-upload-state='uploading']", visible: :all)

    held.continue

    expect(page).to have_content("Sua página está no ar, Ana")
    tenant = Tenant.find_by(subdomain: "barbearia-do-ze")
    expect(ActsAsTenant.with_tenant(tenant) { tenant.branding.logo }).to be_attached
  end

  it "says the upload failed instead of pretending it was accepted" do
    reach_logo_question
    page.driver.browser.on(:request) { |request| request.abort }
    page.driver.browser.network.intercept(pattern: "*direct_uploads*")

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))

    expect(page).to have_content("Não deu para enviar a logo")
    expect(page).to have_css("[data-upload-state='failed']")
    expect(find("[data-logo-target='signedId']", visible: :all).value).to be_blank
  end

  it "refuses a file over the size limit before any upload starts" do
    reach_logo_question
    oversized = Tempfile.new([ "huge", ".png" ])
    oversized.write("0" * (Branding::LOGO_MAX_BYTES + 1))
    oversized.rewind

    find("input[type=file]", visible: :all, match: :first).attach_file(oversized.path)

    expect(page).to have_content("não foi aceita")
    expect(direct_upload_requests).to eq(0)
    expect(page).to have_css("img[data-logo-target='preview'][hidden]", visible: :all)
  end

  it "refuses a file whose type is not in the allowlist before any upload starts" do
    reach_logo_question

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/not-an-image.txt"))

    expect(page).to have_content("não foi aceita")
    expect(direct_upload_requests).to eq(0)
  end
end
