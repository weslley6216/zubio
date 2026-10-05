require "rails_helper"

RSpec.describe "Onboarding journey", type: :system, js: true do
  it "crosses the five questions without loading a page" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
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
    %w[Ter Qua Qui Sex Sáb].each { |weekday| find("label", text: weekday, exact_text: true).click }
    fill_in "working_hours_opens_at", with: "09:00"
    fill_in "working_hours_closes_at", with: "18:00"

    expect(page.driver.network_traffic.count { |exchange| exchange.request&.type?("document") }).to eq(0)
  end

  it "publishes the page once the last question is answered" do
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

    click_on "Ver minha página"

    expect(page).to have_content("Sua página está no ar, Ana")
    expect(page).to have_content("barbearia-do-ze.zubio.com.br")
    expect(page).to have_content("1 serviço")
  end

  it "keeps every answer when the schedule is refused" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    attach_file("Galeria", Rails.root.join("spec/fixtures/files/logo.png"), make_visible: true)
    find("[data-logo-target='signedId']", visible: :all) { |field| field.value.present? }
    click_on "Continuar"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    %w[Ter Qua Qui Sex Sáb].each { |weekday| find("label", text: weekday, exact_text: true).click }
    fill_in "working_hours_opens_at", with: "18:00"
    fill_in "working_hours_closes_at", with: "09:00"
    find("label:has([data-onboarding-target='breakToggle'])").click
    find("[data-onboarding-target='breakSummary']").click
    fill_in "working_hours_break_starts_at", with: "12:30"
    fill_in "working_hours_break_ends_at", with: "13:30"

    click_on "Ver minha página"

    expect(page).to have_content(Owner::OnboardingController::REFUSED)
    expect(page).to have_css(%(input[name="working_hours[weekdays][]"][value="2"]:checked), visible: :all)
    expect(find("#working_hours_break_starts_at", visible: :all).value).to eq("12:30")
    expect(find("#working_hours_break_ends_at", visible: :all).value).to eq("13:30")
    expect(find("[data-onboarding-target='breakToggle']", visible: :all)).to be_checked
    expect(find(%(img[data-logo-target="preview"]), visible: :all)[:src]).to be_present
  end

  it "finishes with the restored logo and lunch once the refused schedule is fixed" do
    tenant = create(:tenant, :onboarding)
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: tenant)
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    attach_file("Galeria", Rails.root.join("spec/fixtures/files/logo.png"), make_visible: true)
    find("[data-logo-target='signedId']", visible: :all) { |field| field.value.present? }
    click_on "Continuar"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    %w[Ter Qua Qui Sex Sáb].each { |weekday| find("label", text: weekday, exact_text: true).click }
    fill_in "working_hours_opens_at", with: "18:00"
    fill_in "working_hours_closes_at", with: "09:00"
    find("label:has([data-onboarding-target='breakToggle'])").click
    find("[data-onboarding-target='breakSummary']").click
    fill_in "working_hours_break_starts_at", with: "12:30"
    fill_in "working_hours_break_ends_at", with: "13:30"
    click_on "Ver minha página"
    find("[data-alert]", text: Owner::OnboardingController::REFUSED)

    fill_in "working_hours_opens_at", with: "09:00"
    fill_in "working_hours_closes_at", with: "18:00"
    click_on "Ver minha página"

    expect(page).to have_content("Sua página está no ar, Ana")
    expect(ActsAsTenant.with_tenant(tenant) { tenant.reload.branding.logo }).to be_attached
    expect(ActsAsTenant.with_tenant(tenant) { owner.professional.working_hours.ordered.map { |working_hour| [ working_hour.weekday, working_hour.opens_at.strftime("%H:%M"), working_hour.closes_at.strftime("%H:%M") ] } })
      .to eq((2..6).flat_map { |weekday| [ [ weekday, "09:00", "12:30" ], [ weekday, "13:30", "18:00" ] ] })
  end

  it "adds a service through the card and sees it listed above a cleared registration card" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
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
    expect(page).to have_content("30min · R$ 45,00")
    expect(find_field("Nome", with: "")).to be_present
  end

  it "goes back, changes the colour and keeps the other answers on submit" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
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
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"

    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"

    expect(page).to have_content("Tem uma logo?")
    expect(page).to have_css("[data-onboarding-section='logo'] [data-brand-initial]", text: "B", exact_text: true)
  end

  it "resumes where it was left off on the same browser" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"

    page.refresh

    expect(page).to have_content("Tem uma logo?")
    expect(find_field("Nome da marca", visible: :all).value).to eq("Barbearia do Zé")
  end

  it "uploads the logo in the background and attaches it to its own establishment by the end" do
    other_tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: other_tenant)
    tenant = create(:tenant, :onboarding)
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: tenant)
    sign_in_owner(owner)
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
    %w[Ter Qua].each { |weekday| find("label", text: weekday, exact_text: true).click }
    fill_in "working_hours_opens_at", with: "09:00"
    fill_in "working_hours_closes_at", with: "18:00"

    click_on "Ver minha página"

    expect(page).to have_content("Sua página está no ar, Ana")
    expect(page).to have_no_content(Views::Owner::Onboarding::Final::LOGO_NOTICE)
    expect(page).to have_css("main img")
    expect(ActsAsTenant.with_tenant(tenant) { tenant.reload.branding.logo }).to be_attached
    expect(ActsAsTenant.with_tenant(other_tenant) { other_tenant.branding.logo }).not_to be_attached
  end

  it "shows the chosen image as a preview, drops the 'no logo' card and fills the signed id" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))

    expect(page).to have_css("[data-onboarding-section='logo'] img[data-logo-target='preview']:not([hidden])")
    expect(page).to have_css("img[data-logo-target='preview']") { |preview| preview.evaluate_script("this.naturalWidth") > 0 }
    expect(page).to have_no_content(Components::Owner::BrandQuestion::Logo::NO_LOGO_TEXT)
    expect(page).to have_css("[data-logo-target='signedId']", visible: :all) { |field| field.value.present? }
  end

  it "reports the upload state while it settles" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))

    expect(page).to have_content("Logo enviada")
    expect(page).to have_css("[data-upload-state='done']")
    expect(page.driver.network_traffic.count { |exchange| exchange.url&.include?("/rails/active_storage/direct_uploads") }).to be_positive
  end

  it "keeps the newest choice when an older upload settles last" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    held = []
    page.driver.browser.on(:request) { |request| held << request }
    page.driver.browser.network.intercept(pattern: "*direct_uploads*")
    picker = find("input[type=file]", visible: :all, match: :first)
    picker.attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    wait_until { held.size == 1 }
    picker.attach_file(Rails.root.join("spec/fixtures/files/another-logo.png"))
    wait_until { held.size == 2 }
    held.last.continue
    find("[data-upload-state='done']")
    newest_signed_id = find("[data-logo-target='signedId']", visible: :all).value

    held.first.continue
    wait_until { page.driver.network_traffic.count { |exchange| exchange.url&.include?("/rails/active_storage/disk/") && exchange.finished? } == 2 }

    expect(page).to have_css("[data-upload-state='done']")
    expect(find("[data-logo-target='signedId']", visible: :all).value).to eq(newest_signed_id)
  end

  it "drops the previous signed id as soon as a new file starts uploading" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    picker = find("input[type=file]", visible: :all, match: :first)
    picker.attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    find("[data-upload-state='done']")
    page.driver.browser.on(:request) { |request| request }
    page.driver.browser.network.intercept(pattern: "*direct_uploads*")

    picker.attach_file(Rails.root.join("spec/fixtures/files/another-logo.png"))

    expect(page).to have_css("[data-upload-state='uploading']")
    expect(page).to have_css("[data-logo-target='signedId']", visible: :all) { |field| field.value.blank? }
  end

  it "forgets an accepted upload when a later file is refused" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    find("[data-upload-state='done']")

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/not-an-image.txt"))

    expect(page).to have_content("não foi aceita")
    expect(page).to have_no_css("[data-upload-state]", visible: :all)
    expect(find("[data-logo-target='signedId']", visible: :all).value).to be_blank
    expect(page).to have_content(Components::Owner::BrandQuestion::Logo::NO_LOGO_TEXT)
  end

  it "holds the submit while the logo is still uploading" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    page.driver.browser.on(:request) { |request| request }
    page.driver.browser.network.intercept(pattern: "*direct_uploads*")
    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    find("[data-upload-state='uploading']")
    click_on "Continuar"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    %w[Ter Qua].each { |weekday| find("label", text: weekday, exact_text: true).click }
    fill_in "working_hours_opens_at", with: "09:00"
    fill_in "working_hours_closes_at", with: "18:00"

    click_on "Ver minha página"

    expect(page).to have_button("Enviando a sua logo…", disabled: true)
    expect(page).to have_no_content("Sua página está no ar")
    expect(page).to have_css("[data-upload-state='uploading']", visible: :all)
  end

  it "submits with the logo attached once the pending upload settles" do
    tenant = create(:tenant, :onboarding)
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: tenant)
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    held = nil
    page.driver.browser.on(:request) { |request| held = request }
    page.driver.browser.network.intercept(pattern: "*direct_uploads*")
    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    find("[data-upload-state='uploading']")
    click_on "Continuar"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    %w[Ter Qua].each { |weekday| find("label", text: weekday, exact_text: true).click }
    fill_in "working_hours_opens_at", with: "09:00"
    fill_in "working_hours_closes_at", with: "18:00"
    click_on "Ver minha página"
    find_button("Enviando a sua logo…", disabled: true)

    held.continue

    expect(page).to have_content("Sua página está no ar, Ana")
    expect(ActsAsTenant.with_tenant(tenant) { tenant.reload.branding.logo }).to be_attached
  end

  it "says the upload failed instead of pretending it was accepted" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    page.driver.browser.on(:request) { |request| request.abort }
    page.driver.browser.network.intercept(pattern: "*direct_uploads*")

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))

    expect(page).to have_content("Não deu para enviar a logo")
    expect(page).to have_css("[data-upload-state='failed']")
    expect(find("[data-logo-target='signedId']", visible: :all).value).to be_blank
    expect(page).to have_css("img[data-logo-target='preview'][hidden]", visible: :all)
    expect(page).to have_content(Components::Owner::BrandQuestion::Logo::NO_LOGO_TEXT)
  end

  it "refuses a file over the size limit before any upload starts" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    oversized = Tempfile.new([ "huge", ".png" ])
    oversized.write("0" * (Branding::LOGO_MAX_BYTES + 1))
    oversized.rewind

    find("input[type=file]", visible: :all, match: :first).attach_file(oversized.path)

    expect(page).to have_content("não foi aceita")
    expect(page.driver.network_traffic.count { |exchange| exchange.url&.include?("/rails/active_storage/direct_uploads") }).to eq(0)
    expect(page).to have_css("img[data-logo-target='preview'][hidden]", visible: :all)
  end

  it "refuses a file whose type is not in the allowlist before any upload starts" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/not-an-image.txt"))

    expect(page).to have_content("não foi aceita")
    expect(page.driver.network_traffic.count { |exchange| exchange.url&.include?("/rails/active_storage/direct_uploads") }).to eq(0)
  end

  it "paints the current screen the moment a swatch is chosen" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    chosen = Branding::Palette::SUGGESTIONS.fetch(:brand_600)[1]
    continue_button = within("[data-onboarding-section='colors']") { find_button("Continuar") }
    painted_before = continue_button.evaluate_script("getComputedStyle(this).backgroundColor")

    find("[data-swatch-row] [data-swatch='#{chosen}']").click

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#{chosen}']", visible: :all)
    expect(continue_button.evaluate_script("getComputedStyle(this).backgroundColor")).not_to eq(painted_before)
    expect(first("[data-progress-bar] .bg-brand-600", visible: :all).evaluate_script("getComputedStyle(this).backgroundColor"))
      .to eq(continue_button.evaluate_script("getComputedStyle(this).backgroundColor"))
  end

  it "carries the chosen color into the next questions" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    chosen = Branding::Palette::SUGGESTIONS.fetch(:brand_600)[1]
    find("[data-swatch-row] [data-swatch='#{chosen}']").click

    click_on "Continuar"

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#{chosen}']", visible: :all)
    expect(within("[data-onboarding-section='name']") { find_button("Continuar") }.evaluate_script("getComputedStyle(this).backgroundColor"))
      .to eq(within("[data-onboarding-section='colors']", visible: :all) { find_button("Continuar", visible: :all) }.evaluate_script("getComputedStyle(this).backgroundColor"))
  end

  it "repaints the screen from a code typed behind the plus" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    within(%(fieldset[aria-label="Cor principal"])) do
      find("label:has([data-more-toggle])").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end

    fill_in "branding[brand_600_custom]", with: "#2C6CB0"

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)
    expect(within("[data-onboarding-section='colors']") { find_button("Continuar") }.evaluate_script("getComputedStyle(this).backgroundColor"))
      .to eq("rgb(44, 108, 176)")
  end

  it "uses the typed support color for the preview today badge" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    within(%(fieldset[aria-label="Cor de apoio"])) do
      find("label:has([data-more-toggle])").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end

    fill_in "branding[brand_secondary_600_custom]", with: "#E8493C"

    expect(page).to have_css("[data-color-swatch-target='preview'][data-preview-secondary='#E8493C']", visible: :all)
  end

  it "flags an invalid code and keeps the last valid color" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    within(%(fieldset[aria-label="Cor principal"])) do
      find("label:has([data-more-toggle])").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end
    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    find("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)

    fill_in "branding[brand_600_custom]", with: "#ZZZ123"

    expect(find(%(input[name="branding[brand_600_custom]"]))["aria-invalid"]).to eq("true")
    expect(find(%(input[name="branding[brand_600_custom]"]))["aria-describedby"]).to eq("brand_600-color-error")
    expect(find("#brand_600-color-error")).to be_visible
    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)
  end

  it "repaints the screen from a restored swatch after a reload" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch='#1E60C4']").click
    click_on "Continuar"

    page.refresh

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#1E60C4']", visible: :all)
    expect(within("[data-onboarding-section='colors']", visible: :all) { find_button("Continuar", visible: :all) }.evaluate_script("getComputedStyle(this).backgroundColor"))
      .to eq("rgb(30, 96, 196)")
  end

  it "repaints the screen from a restored typed color after a reload" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    within(%(fieldset[aria-label="Cor principal"])) do
      find("label:has([data-more-toggle])").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end
    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    find("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)
    click_on "Continuar"

    page.refresh

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)
    expect(within("[data-onboarding-section='colors']", visible: :all) { find_button("Continuar", visible: :all) }.evaluate_script("getComputedStyle(this).backgroundColor"))
      .to eq("rgb(44, 108, 176)")
  end

  it "opens the plus without repainting the screen" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"

    within(%(fieldset[aria-label="Cor principal"])) { find("label:has([data-more-toggle])").click }

    expect(page).to have_css(%(fieldset[aria-label="Cor principal"] [data-swatch='#{Branding::Palette.extras(:brand_600).first}']))
    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#{Branding::DEFAULT_BRAND_600}']", visible: :all)
  end

  it "repaints the screen from a swatch revealed behind the plus" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    extra = Branding::Palette.extras(:brand_600).first
    within(%(fieldset[aria-label="Cor principal"])) { find("label:has([data-more-toggle])").click }

    find(%(fieldset[aria-label="Cor principal"] [data-swatch='#{extra}'])).click

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#{extra}']", visible: :all)
  end

  it "keeps a swatch chosen while a typed color's sheet was still loading" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    within(%(fieldset[aria-label="Cor principal"])) do
      find("label:has([data-more-toggle])").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end
    held = []
    page.driver.browser.network.intercept(pattern: "*preview.css*")
    page.driver.browser.on(:request) { |request| held << request }
    page.execute_script(<<~JS)
      window.previewSheets = []
      const record = (state) => (event) => {
        if (event.target.id?.startsWith("preview-sheet")) window.previewSheets.push(`${state} ${event.target.href}`)
      }
      document.addEventListener("load", record("loaded"), true)
      document.addEventListener("error", record("failed"), true)
    JS
    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    wait_until { held.any? { |request| request.url.include?("2C6CB0") } }
    find("[data-swatch-row] [data-swatch='#1E60C4']").click
    find("[data-controller='onboarding'][data-preview-brand='#1E60C4']", visible: :all)

    held.each(&:continue)
    wait_until { page.evaluate_script("window.previewSheets").any? { |entry| entry.start_with?("loaded") && entry.include?("%232C6CB0") } }
    page.evaluate_async_script("setTimeout(arguments[0], 0)")

    expect(find("[data-controller='onboarding']", visible: :all)["data-preview-brand"]).to eq("#1E60C4")
  end

  it "keeps the last painted color when a typed color's sheet fails to load" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    within(%(fieldset[aria-label="Cor principal"])) do
      find("label:has([data-more-toggle])").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end
    page.driver.browser.network.intercept(pattern: "*preview.css*")
    page.driver.browser.on(:request) { |request| request.url.include?("2C6CB0") ? request.abort : request.continue }
    page.execute_script(<<~JS)
      window.previewSheets = []
      const record = (state) => (event) => {
        if (event.target.id?.startsWith("preview-sheet")) window.previewSheets.push(`${state} ${event.target.href}`)
      }
      document.addEventListener("load", record("loaded"), true)
      document.addEventListener("error", record("failed"), true)
    JS

    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    wait_until { page.evaluate_script("window.previewSheets").any? { |entry| entry.start_with?("failed") && entry.include?("%232C6CB0") } }
    page.evaluate_async_script("setTimeout(arguments[0], 0)")

    expect(find("[data-controller='onboarding']", visible: :all)["data-preview-brand"]).to eq(Branding::DEFAULT_BRAND_600)
  end

  it "fetches a typed color's sheet again after a failed load and repaints" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    within(%(fieldset[aria-label="Cor principal"])) do
      find("label:has([data-more-toggle])").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end
    attempts = 0
    page.driver.browser.network.intercept(pattern: "*preview.css*")
    page.driver.browser.on(:request) { |request| (attempts += 1) == 1 ? request.abort : request.continue }
    page.execute_script(<<~JS)
      window.previewSheets = []
      const record = (state) => (event) => {
        if (event.target.id?.startsWith("preview-sheet")) window.previewSheets.push(`${state} ${event.target.href}`)
      }
      document.addEventListener("load", record("loaded"), true)
      document.addEventListener("error", record("failed"), true)
    JS
    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    wait_until { page.evaluate_script("window.previewSheets").any? { |entry| entry.start_with?("failed") && entry.include?("%232C6CB0") } }
    page.evaluate_async_script("setTimeout(arguments[0], 0)")

    fill_in "branding[brand_600_custom]", with: "#2C6CB0"

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)
    expect(within("[data-onboarding-section='colors']") { find_button("Continuar") }.evaluate_script("getComputedStyle(this).backgroundColor"))
      .to eq("rgb(44, 108, 176)")
  end

  it "opens the native color picker the moment the customize card is tapped" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    page.execute_script(<<~JS)
      window.pickerOpenings = 0
      HTMLInputElement.prototype.showPicker = function () { window.pickerOpenings += 1 }
    JS

    within(%(fieldset[aria-label="Cor principal"])) do
      find("label:has([data-more-toggle])").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end

    expect(page.evaluate_script("window.pickerOpenings")).to eq(1)
  end

  it "keeps the native color picker closed when the customize choice comes from script" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    page.execute_script(<<~JS)
      window.pickerOpenings = 0
      HTMLInputElement.prototype.showPicker = function () { window.pickerOpenings += 1 }
    JS

    page.execute_script(<<~JS)
      const radio = document.querySelector('input[name="branding[brand_600]"][value="custom"]')
      radio.checked = true
      radio.dispatchEvent(new Event("change", { bubbles: true }))
    JS

    expect(find(%(input[name="branding[brand_600]"][value="custom"]), visible: :all)).to be_checked
    expect(page.evaluate_script("window.pickerOpenings")).to eq(0)
  end

  it "labels a service on the client before it is ever sent" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"

    fill_in "Nome", with: "Corte + barba"
    fill_in "Duração (minutos)", with: "60"
    fill_in "Preço (R$, opcional)", with: "80"
    click_on "Adicionar à lista"

    expect(find("[data-service-meta]", visible: :all).text(:all)).to eq("1h · R$ 80,00")
  end

  it "labels a service the same way after a server refusal" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte + barba"
    fill_in "Duração (minutos)", with: "60"
    fill_in "Preço (R$, opcional)", with: "80"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    find("label", text: "Ter", exact_text: true).click
    fill_in "working_hours_opens_at", with: "18:00"
    fill_in "working_hours_closes_at", with: "09:00"

    click_on "Ver minha página"

    expect(page).to have_content(Owner::OnboardingController::REFUSED)
    expect(find("[data-service-meta]", visible: :all).text(:all)).to eq("1h · R$ 80,00")
  end

  it "labels every price shape on the client" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"

    [ "80", "80,5", "1.200", "", "abc" ].each_with_index do |price, index|
      fill_in "Nome", with: "Service #{index}"
      fill_in "Duração (minutos)", with: "30"
      fill_in "Preço (R$, opcional)", with: price
      click_on "Adicionar à lista"
    end

    expect(all("[data-service-meta]", visible: :all).map { |meta| meta.text(:all) }).to eq([
      "30min · R$ 80,00",
      "30min · R$ 80,50",
      "30min · R$ 1.200,00",
      "30min · #{Service::Price::UNPRICED_LABEL}",
      "30min · #{Service::Price::UNPRICED_LABEL}"
    ])
  end

  it "labels every price shape the same way after a server refusal" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    [ "80", "80,5", "1.200", "", "abc" ].each_with_index do |price, index|
      fill_in "Nome", with: "Service #{index}"
      fill_in "Duração (minutos)", with: "30"
      fill_in "Preço (R$, opcional)", with: price
      click_on "Adicionar à lista"
    end
    click_on "Continuar com 5 serviços"
    find("label", text: "Ter", exact_text: true).click
    fill_in "working_hours_opens_at", with: "09:00"
    fill_in "working_hours_closes_at", with: "18:00"

    click_on "Ver minha página"

    expect(page).to have_content(Owner::OnboardingController::REFUSED)
    expect(all("[data-service-meta]", visible: :all).map { |meta| meta.text(:all) }).to eq([
      "30min · R$ 80,00",
      "30min · R$ 80,50",
      "30min · R$ 1.200,00",
      "30min · #{Service::Price::UNPRICED_LABEL}",
      "30min · #{Service::Price::UNPRICED_LABEL}"
    ])
  end

  it "keeps the service in the list, marked for editing, with its values in the card" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "30"
    fill_in "Preço (R$, opcional)", with: "40,00"
    click_on "Adicionar à lista"
    fill_in "Nome", with: "Corte + barba"
    fill_in "Duração (minutos)", with: "60"
    fill_in "Preço (R$, opcional)", with: "80,00"
    click_on "Adicionar à lista"

    within(all("[data-service-row]").last) { click_on "Editar" }

    expect(page).to have_css("[data-service-row][data-editing='true']", text: "Corte + barba")
    expect(page).to have_css("[data-service-row]", count: 2)
    expect(find_field("Nome").value).to eq("Corte + barba")
    expect(find_field("Duração (minutos)").value).to eq("60")
  end

  it "keeps the edited service in its place with the new values" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "30"
    fill_in "Preço (R$, opcional)", with: "40,00"
    click_on "Adicionar à lista"
    fill_in "Nome", with: "Corte + barba"
    fill_in "Duração (minutos)", with: "60"
    fill_in "Preço (R$, opcional)", with: "80,00"
    click_on "Adicionar à lista"

    within(first("[data-service-row]")) { click_on "Editar" }
    fill_in "Preço (R$, opcional)", with: "55,00"
    click_on "Salvar alterações"

    expect(all("[data-service-name]").map(&:text)).to eq([ "Corte", "Corte + barba" ])
    expect(all("[data-service-meta]").map(&:text)).to eq([ "30min · R$ 55,00", "1h · R$ 80,00" ])
  end

  it "discards an unconfirmed edit when another service is picked for editing" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "30"
    fill_in "Preço (R$, opcional)", with: "40,00"
    click_on "Adicionar à lista"
    fill_in "Nome", with: "Corte + barba"
    fill_in "Duração (minutos)", with: "60"
    fill_in "Preço (R$, opcional)", with: "80,00"
    click_on "Adicionar à lista"

    within(first("[data-service-row]")) { click_on "Editar" }
    fill_in "Preço (R$, opcional)", with: "55,00"
    within(all("[data-service-row]").last) { click_on "Editar" }
    fill_in "Preço (R$, opcional)", with: "95,00"
    click_on "Salvar alterações"

    expect(all("[data-service-meta]").map(&:text)).to eq([ "30min · R$ 40,00", "1h · R$ 95,00" ])
    expect(page).to have_no_css("[data-service-row][data-editing]", visible: :all)
  end

  it "leaves editing when the service being edited is removed" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "30"
    fill_in "Preço (R$, opcional)", with: "40,00"
    click_on "Adicionar à lista"
    fill_in "Nome", with: "Corte + barba"
    fill_in "Duração (minutos)", with: "60"
    fill_in "Preço (R$, opcional)", with: "80,00"
    click_on "Adicionar à lista"

    within(first("[data-service-row]")) { click_on "Editar" }
    within(first("[data-service-row]")) { click_on "Remover" }
    fill_in "Nome", with: "Barba"
    fill_in "Duração (minutos)", with: "20"
    fill_in "Preço (R$, opcional)", with: "30,00"
    click_on "Adicionar à lista"

    expect(all("[data-service-name]").map(&:text)).to eq([ "Corte + barba", "Barba" ])
    expect(page).to have_css("[data-onboarding-target='commitLabel']", text: "Adicionar à lista")
  end

  it "drops the server's error from a refused service once it is edited and saved" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "30"
    fill_in "Preço (R$, opcional)", with: "abc"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    find("label", text: "Ter", exact_text: true).click
    fill_in "working_hours_opens_at", with: "09:00"
    fill_in "working_hours_closes_at", with: "18:00"
    click_on "Ver minha página"
    find("[data-service-row]", text: Service::PRICE_UNREADABLE_MESSAGE)

    within(first("[data-service-row]")) { click_on "Editar" }
    fill_in "Preço (R$, opcional)", with: "80,00"
    click_on "Salvar alterações"

    expect(first("[data-service-row]")).to have_text("30min · R$ 80,00")
    expect(first("[data-service-row]")).to have_no_text(Service::PRICE_UNREADABLE_MESSAGE)
  end

  it "clears the missing-name warning when a service is picked for editing" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "30"
    fill_in "Preço (R$, opcional)", with: "40,00"
    click_on "Adicionar à lista"
    click_on "Adicionar à lista"
    find("body", text: Service::NAME_REQUIRED_MESSAGE)

    within(first("[data-service-row]")) { click_on "Editar" }

    expect(find_field("Nome")["aria-invalid"]).to be_nil
    expect(page).to have_no_content(Service::NAME_REQUIRED_MESSAGE)
  end

  it "clears the missing-name warning when leaving the services step" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    click_on "Adicionar à lista"
    find("body", text: Service::NAME_REQUIRED_MESSAGE)

    find("[data-onboarding-target='back']").click

    expect(page).to have_css("[data-onboarding-section='logo']:not([hidden])")
    expect(find("#service_name", visible: :all)["aria-invalid"]).to be_nil
    expect(page.evaluate_script("document.getElementById('service_name-error').hidden")).to be(true)
  end

  it "keeps the service with its previous values when leaving the step mid-edit" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "30"
    fill_in "Preço (R$, opcional)", with: "40,00"
    click_on "Adicionar à lista"
    fill_in "Nome", with: "Corte + barba"
    fill_in "Duração (minutos)", with: "60"
    fill_in "Preço (R$, opcional)", with: "80,00"
    click_on "Adicionar à lista"

    within(all("[data-service-row]").last) { click_on "Editar" }
    fill_in "Preço (R$, opcional)", with: "95,00"
    find("[data-onboarding-target='back']").click

    expect(page).to have_css("[data-onboarding-section='logo']:not([hidden])")
    expect(page).to have_css("[data-service-row]", count: 2, visible: :all)
    expect(find("[data-service-row]", text: "Corte + barba", visible: :all).text(:all)).to include("1h · R$ 80,00")
    expect(page).to have_no_css("[data-service-row][data-editing='true']", visible: :all)
  end

  it "flags the name field as required when adding without a name" do
    owner = create(:user, :with_professional, name: "Ana Lima", tenant: create(:tenant, :onboarding))
    sign_in_owner(owner)
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"

    click_on "Adicionar à lista"

    expect(find_field("Nome")["aria-invalid"]).to eq("true")
    expect(page).to have_content(Service::NAME_REQUIRED_MESSAGE)
    expect(page).to have_no_css("[data-service-row]", visible: :all)
  end
end
