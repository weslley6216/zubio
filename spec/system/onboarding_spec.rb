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

  def finished_storage_uploads
    page.driver.network_traffic.count { |exchange| exchange.url&.include?("/rails/active_storage/disk/") && exchange.finished? }
  end

  def wait_until(&condition)
    Timeout.timeout(Capybara.default_max_wait_time) { sleep 0.05 until condition.call }
  end

  def another_logo
    @another_logo = Tempfile.new([ "another-logo", ".png" ])
    @another_logo.binmode
    @another_logo.write(File.binread(Rails.root.join("spec/fixtures/files/logo.png")))
    @another_logo.rewind
    @another_logo.path
  end

  def signed_id
    find("[data-logo-target='signedId']", visible: :all).value
  end

  def fill_time(field_id, value)
    page.execute_script(<<~JS, field_id, value)
      const field = document.getElementById(arguments[0])
      field.value = arguments[1]
      field.dispatchEvent(new Event("input", { bubbles: true }))
    JS
  end

  def reach_services_with_two
    sign_up_and_reach_onboarding
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
  end

  def service_rows = all("[data-service-row]", visible: :all)

  def edit_button = "button[aria-label='#{Views::Owner::Onboarding::Document::EDIT_LABEL}']"

  def reach_logo_question
    sign_up_and_reach_onboarding
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
  end

  def computed_bg(node)
    node.evaluate_script("getComputedStyle(this).backgroundColor")
  end

  def colors_continue = within("[data-onboarding-section='colors']", visible: :all) { find_button("Continuar", visible: :all) }

  def root_brand = find("[data-controller='onboarding']", visible: :all)["data-preview-brand"]

  def brand_fieldset = %(fieldset[aria-label="#{Components::Owner::BrandQuestion::Colors::BRAND_LABEL}"])

  def watch_preview_sheets
    page.execute_script(<<~JS)
      window.previewSheets = []
      const record = (state) => (event) => {
        if (event.target.id?.startsWith("preview-sheet")) window.previewSheets.push(`${state} ${event.target.href}`)
      }
      document.addEventListener("load", record("loaded"), true)
      document.addEventListener("error", record("failed"), true)
    JS
  end

  def wait_for_preview_sheet(state, hex)
    encoded = ERB::Util.url_encode(hex)
    wait_until { page.evaluate_script("window.previewSheets").any? { |entry| entry.start_with?(state) && entry.include?(encoded) } }
    page.evaluate_async_script("setTimeout(arguments[0], 0)")
  end

  def count_picker_openings
    page.execute_script(<<~JS)
      window.pickerOpenings = 0
      HTMLInputElement.prototype.showPicker = function () { window.pickerOpenings += 1 }
    JS
  end

  def open_customize(fieldset_label)
    within(%(fieldset[aria-label="#{fieldset_label}"])) do
      find("label:has([data-more-toggle])").click
      choose(option: Branding::CUSTOM_COLOR_CHOICE, allow_label_click: true)
    end
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

  it "keeps every answer on a refused submit, then finishes once the schedule is fixed" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    attach_file(Components::Owner::BrandQuestion::Logo::GALLERY_LABEL, another_logo, make_visible: true)
    wait_until { signed_id.present? }
    click_on "Continuar"
    fill_in "Nome", with: "Corte"
    fill_in "Duração (minutos)", with: "45"
    fill_in "Preço (R$, opcional)", with: "90,00"
    click_on "Adicionar à lista"
    click_on "Continuar com 1 serviço"
    %w[2 3 4 5 6].each { |weekday| find("label", text: WorkingHour::WEEKDAY_NAMES[weekday.to_i].first(3), exact_text: true).click }
    fill_time("working_hours_opens_at", "18:00")
    fill_time("working_hours_closes_at", "09:00")
    find("label:has([data-onboarding-target='breakToggle'])").click
    fill_time("working_hours_break_starts_at", "12:00")
    fill_time("working_hours_break_ends_at", "14:00")

    click_on "Ver minha página"

    expect(page).to have_content(Owner::OnboardingController::REFUSED)
    expect(page).to have_css(%(input[name="working_hours[weekdays][]"][value="2"]:checked), visible: :all)
    expect(find("#working_hours_break_starts_at", visible: :all).value).to eq("12:00")
    expect(find("[data-onboarding-target='breakToggle']", visible: :all)).to be_checked
    expect(find(%(img[data-logo-target="preview"]), visible: :all)[:src]).to be_present

    fill_time("working_hours_opens_at", "09:00")
    fill_time("working_hours_closes_at", "18:00")
    click_on "Ver minha página"

    expect(page).to have_content("Sua página está no ar, Ana")
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
    expect(page).to have_content("30min · R$ 45,00")
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
    expect(page).to have_css("img[data-logo-target='preview']") { |preview| preview.evaluate_script("this.naturalWidth") > 0 }
    expect(page).to have_no_content(Components::Owner::BrandQuestion::Logo::NO_LOGO_TEXT)
    expect(page).to have_css("[data-logo-target='signedId']", visible: :all)
    expect(find("[data-logo-target='signedId']", visible: :all).value).to be_present
  end

  it "reports the upload state while it settles" do
    reach_logo_question

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))

    expect(page).to have_content("Logo enviada")
    expect(page).to have_css("[data-upload-state='done']")
    expect(direct_upload_requests).to be_positive
  end

  it "keeps the newest choice when an older upload settles last" do
    reach_logo_question
    held = []
    page.driver.browser.on(:request) { |request| held << request }
    page.driver.browser.network.intercept(pattern: "*direct_uploads*")
    picker = find("input[type=file]", visible: :all, match: :first)
    picker.attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    wait_until { held.size == 1 }
    picker.attach_file(another_logo)
    wait_until { held.size == 2 }
    held.last.continue
    expect(page).to have_css("[data-upload-state='done']")
    newest = signed_id

    held.first.continue
    wait_until { finished_storage_uploads == 2 }

    expect(page).to have_css("[data-upload-state='done']")
    expect(signed_id).to eq(newest)
  end

  it "drops the previous signed id as soon as a new file starts uploading" do
    reach_logo_question
    picker = find("input[type=file]", visible: :all, match: :first)
    picker.attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    expect(page).to have_css("[data-upload-state='done']")
    page.driver.browser.on(:request) { |request| request }
    page.driver.browser.network.intercept(pattern: "*direct_uploads*")

    picker.attach_file(another_logo)

    expect(page).to have_css("[data-upload-state='uploading']")
    expect(page).to have_css("[data-logo-target='signedId']", visible: :all) { |field| field.value.blank? }
  end

  it "forgets an accepted upload when a later file is refused" do
    reach_logo_question
    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/logo.png"))
    expect(page).to have_css("[data-upload-state='done']")

    find("input[type=file]", visible: :all, match: :first).attach_file(Rails.root.join("spec/fixtures/files/not-an-image.txt"))

    expect(page).to have_content("não foi aceita")
    expect(page).to have_no_css("[data-upload-state]", visible: :all)
    expect(signed_id).to be_blank
    expect(page).to have_content(Components::Owner::BrandQuestion::Logo::NO_LOGO_TEXT)
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

    expect(page).to have_button("Enviando a sua logo…", disabled: true)
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
    expect(signed_id).to be_blank
    expect(page).to have_css("img[data-logo-target='preview'][hidden]", visible: :all)
    expect(page).to have_content(Components::Owner::BrandQuestion::Logo::NO_LOGO_TEXT)
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

  it "paints the current screen the moment a swatch is chosen (AC1)" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    chosen = Branding::Palette::SUGGESTIONS.fetch(:brand_600)[1]
    button = colors_continue
    before = computed_bg(button)

    find("[data-swatch-row] [data-swatch='#{chosen}']").click

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#{chosen}']", visible: :all)
    expect(computed_bg(button)).not_to eq(before)
    expect(computed_bg(first("[data-progress-bar] .bg-brand-600", visible: :all))).to eq(computed_bg(button))
  end

  it "carries the chosen color into the next questions (AC2)" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    chosen = Branding::Palette::SUGGESTIONS.fetch(:brand_600)[1]
    find("[data-swatch-row] [data-swatch='#{chosen}']").click
    click_on "Continuar"

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#{chosen}']", visible: :all)
    name_button = within("[data-onboarding-section='name']") { find_button("Continuar") }
    expect(computed_bg(name_button)).to eq(computed_bg(colors_continue))
  end

  it "repaints the screen from a code typed behind the plus (AC3)" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    open_customize(Components::Owner::BrandQuestion::Colors::BRAND_LABEL)

    fill_in "branding[brand_600_custom]", with: "#2C6CB0"

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)
    expect(computed_bg(colors_continue)).to eq("rgb(44, 108, 176)")
  end

  it "uses the typed support color for the preview today badge (AC4)" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    open_customize(Components::Owner::BrandQuestion::Colors::SECONDARY_LABEL)

    fill_in "branding[brand_secondary_600_custom]", with: "#E8493C"

    expect(page).to have_css("[data-color-swatch-target='preview'][data-preview-secondary='#E8493C']", visible: :all)
  end

  it "flags an invalid code and keeps the last valid color (AC5)" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    open_customize(Components::Owner::BrandQuestion::Colors::BRAND_LABEL)
    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)

    fill_in "branding[brand_600_custom]", with: "#ZZZ123"

    expect(find(%(input[name="branding[brand_600_custom]"]))["aria-invalid"]).to eq("true")
    expect(find(%(input[name="branding[brand_600_custom]"]))["aria-describedby"]).to eq("brand_600-color-error")
    expect(find("#brand_600-color-error")).to be_visible
    expect(find("[data-controller='onboarding']", visible: :all)["data-preview-brand"]).to eq("#2C6CB0")
  end

  it "repaints the screen from a restored swatch after a reload" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    find("[data-swatch-row] [data-swatch='#1E60C4']").click
    click_on "Continuar"

    page.refresh

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#1E60C4']", visible: :all)
    expect(computed_bg(colors_continue)).to eq("rgb(30, 96, 196)")
  end

  it "repaints the screen from a restored typed color after a reload" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    open_customize(Components::Owner::BrandQuestion::Colors::BRAND_LABEL)
    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)
    click_on "Continuar"

    page.refresh

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)
    expect(computed_bg(colors_continue)).to eq("rgb(44, 108, 176)")
  end

  it "opens the plus without repainting the screen" do
    sign_up_and_reach_onboarding
    click_on "Começar"

    within(brand_fieldset) { find("label:has([data-more-toggle])").click }

    expect(page).to have_css("#{brand_fieldset} [data-swatch='#{Branding::Palette.extras(:brand_600).first}']")
    expect(root_brand).to eq(Branding::DEFAULT_BRAND_600)
  end

  it "repaints the screen from a swatch revealed behind the plus" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    extra = Branding::Palette.extras(:brand_600).first
    within(brand_fieldset) { find("label:has([data-more-toggle])").click }

    find("#{brand_fieldset} [data-swatch='#{extra}']").click

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#{extra}']", visible: :all)
  end

  it "keeps a swatch chosen while a typed color's sheet was still loading" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    open_customize(Components::Owner::BrandQuestion::Colors::BRAND_LABEL)
    held = []
    page.driver.browser.network.intercept(pattern: "*preview.css*")
    page.driver.browser.on(:request) { |request| held << request }
    watch_preview_sheets
    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    wait_until { held.any? { |request| request.url.include?("2C6CB0") } }
    find("[data-swatch-row] [data-swatch='#1E60C4']").click
    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#1E60C4']", visible: :all)

    held.each(&:continue)
    wait_for_preview_sheet("loaded", "#2C6CB0")

    expect(root_brand).to eq("#1E60C4")
  end

  it "keeps the last painted color when a typed color's sheet fails to load" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    open_customize(Components::Owner::BrandQuestion::Colors::BRAND_LABEL)
    page.driver.browser.network.intercept(pattern: "*preview.css*")
    page.driver.browser.on(:request) { |request| request.url.include?("2C6CB0") ? request.abort : request.continue }
    watch_preview_sheets

    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    wait_for_preview_sheet("failed", "#2C6CB0")

    expect(root_brand).to eq(Branding::DEFAULT_BRAND_600)
  end

  it "opens the native color picker the moment the customize card is tapped" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    count_picker_openings

    open_customize(Components::Owner::BrandQuestion::Colors::BRAND_LABEL)

    expect(page.evaluate_script("window.pickerOpenings")).to eq(1)
  end

  it "keeps the native color picker closed when the customize choice comes from script" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    count_picker_openings

    page.execute_script(<<~JS)
      const radio = document.querySelector('input[name="branding[brand_600]"][value="custom"]')
      radio.checked = true
      radio.dispatchEvent(new Event("change", { bubbles: true }))
    JS

    expect(find(%(input[name="branding[brand_600]"][value="custom"]), visible: :all)).to be_checked
    expect(page.evaluate_script("window.pickerOpenings")).to eq(0)
  end

  it "fetches a typed color's sheet again after a failed load and repaints" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    open_customize(Components::Owner::BrandQuestion::Colors::BRAND_LABEL)
    attempts = 0
    page.driver.browser.network.intercept(pattern: "*preview.css*")
    page.driver.browser.on(:request) { |request| (attempts += 1) == 1 ? request.abort : request.continue }
    watch_preview_sheets
    fill_in "branding[brand_600_custom]", with: "#2C6CB0"
    wait_for_preview_sheet("failed", "#2C6CB0")

    fill_in "branding[brand_600_custom]", with: "#2C6CB0"

    expect(page).to have_css("[data-controller='onboarding'][data-preview-brand='#2C6CB0']", visible: :all)
    expect(computed_bg(colors_continue)).to eq("rgb(44, 108, 176)")
  end

  it "renders the same service label on the client and after a server refusal (AC5)" do
    sign_up_and_reach_onboarding
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

    client_label = find("[data-service-meta]", visible: :all).text(:all)

    click_on "Continuar com 1 serviço"
    %w[2].each { |weekday| find("label", text: WorkingHour::WEEKDAY_NAMES[weekday.to_i].first(3), exact_text: true).click }
    fill_time("working_hours_opens_at", "18:00")
    fill_time("working_hours_closes_at", "09:00")
    click_on "Ver minha página"

    expect(page).to have_content(Owner::OnboardingController::REFUSED)
    server_label = find("[data-service-meta]", visible: :all).text(:all)

    expect(client_label).to eq("1h · R$ 80,00")
    expect(server_label).to eq(client_label)
  end

  it "keeps the service in the list, marked for editing, with its values in the card (AC1)" do
    reach_services_with_two

    within(service_rows.last) { find(edit_button).click }

    expect(page).to have_css("[data-service-row][data-editing='true']", text: "Corte + barba")
    expect(service_rows.size).to eq(2)
    expect(find_field("Nome").value).to eq("Corte + barba")
    expect(find_field("Duração (minutos)").value).to eq("60")
  end

  it "keeps the edited service in its place with the new values (AC2)" do
    reach_services_with_two

    within(service_rows.last) { find(edit_button).click }
    fill_in "Preço (R$, opcional)", with: "95,00"
    click_on "Salvar alterações"

    expect(service_rows.size).to eq(2)
    expect(service_rows.last).to have_text("Corte + barba")
    expect(service_rows.last).to have_text("1h · R$ 95,00")
    expect(service_rows.first).to have_text("Corte")
  end

  it "keeps the service with its previous values when advancing mid-edit (AC3)" do
    reach_services_with_two

    within(service_rows.last) { find(edit_button).click }
    fill_in "Preço (R$, opcional)", with: "95,00"
    find("[data-onboarding-target='back']").click

    expect(page).to have_css("[data-onboarding-section='logo']:not([hidden])")
    expect(service_rows.size).to eq(2)
    expect(find("[data-service-row]", text: "Corte + barba", visible: :all).text(:all)).to include("1h · R$ 80,00")
    expect(page).to have_no_css("[data-service-row][data-editing='true']", visible: :all)
  end

  it "flags the name field as required when adding without a name (AC4)" do
    sign_up_and_reach_onboarding
    click_on "Começar"
    find("[data-swatch-row] [data-swatch]", match: :first).click
    click_on "Continuar"
    fill_in "Nome da marca", with: "Barbearia do Zé"
    click_on "Continuar"
    click_on "Pular por enquanto"

    click_on "Adicionar à lista"

    expect(find_field("Nome")["aria-invalid"]).to eq("true")
    expect(page).to have_content(Service::NAME_REQUIRED_MESSAGE)
    expect(service_rows).to be_empty
  end
end
