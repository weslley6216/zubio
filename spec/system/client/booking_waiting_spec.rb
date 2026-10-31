require "rails_helper"

RSpec.describe "Client booking submit lock", type: :system, js: true do
  let(:tenant) { create(:tenant, subdomain: "mary", name: "Mary Sombracelhas") }
  let(:professional) { create(:professional, tenant: tenant) }
  let(:service) { create(:service, tenant: tenant, duration_minutes: 45) }
  let(:day) { Date.current.next_week(:tuesday) }

  before do
    create(:working_hour, tenant: tenant, professional: professional, weekday: day.wday, opens_at: "09:00", closes_at: "12:00")
  end

  it "locks the confirm button on the first tap and sends a single POST" do
    client = create(:client, tenant: tenant)
    sign_in_client(client)
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"
    find("[data-slot]", match: :first).click

    state = submit_lock_state("[data-confirm-bar]", "button.click(); button.click();")

    expect(state["disabled"]).to be(true)
    expect(state["label"]).to eq("Confirmando…")
    expect(page).to have_css("[data-receipt]")
  end

  it "returns to the confirm button with its time after going back" do
    client = create(:client, tenant: tenant)
    sign_in_client(client)
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"
    slot = find("[data-slot]", match: :first)
    slot_time = slot["data-time"]
    slot.click
    click_button "Confirmar #{slot_time}"

    expect(page).to have_css("[data-receipt]")

    page.go_back

    expect(page).to have_css("[data-confirm-bar]:not([disabled])", text: "Confirmar #{slot_time}")
  end

  it "locks on Enter submit too" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"
    find("[data-slot]", match: :first).click
    fill_in "name", with: "Ana Paula Ribeiro"
    fill_in "phone", with: "11988771234"

    state = submit_lock_state("[data-confirm-bar]", 'document.querySelector("form").requestSubmit();')

    expect(state["disabled"]).to be(true)
    expect(state["label"]).to eq("Confirmando…")
  end

  it "refuses a second submit after another slot re-enables the locked button" do
    client = create(:client, tenant: tenant)
    sign_in_client(client)
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"
    find("[data-slot]", match: :first).click

    result = page.evaluate_script(<<~JS)
      (function() {
        const form = document.querySelector("form")
        const button = document.querySelector("[data-confirm-bar]")
        button.click()
        document.querySelectorAll("[data-slot]")[1].click()
        let prevented = null
        form.addEventListener("submit", (event) => { prevented = event.defaultPrevented }, { once: true })
        form.requestSubmit()
        return JSON.stringify({ prevented: prevented, disabled: button.disabled, label: button.textContent })
      })()
    JS

    expect(JSON.parse(result)).to eq("prevented" => true, "disabled" => true, "label" => "Confirmando…")
  end

  it "does not restore on a normal load" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    expect(page).to have_css("[data-confirm-bar][disabled]", exact_text: "Confirmar")
  end
end

RSpec.describe "Client booking time grid skeleton", type: :system, js: true do
  let(:tenant) { create(:tenant, subdomain: "mary", name: "Mary Sombracelhas") }
  let(:professional) { create(:professional, tenant: tenant) }
  let(:service) { create(:service, tenant: tenant, duration_minutes: 45) }
  let(:day) { Date.current.next_week(:tuesday) }

  before do
    create(:working_hour, tenant: tenant, professional: professional, weekday: day.wday, opens_at: "09:00", closes_at: "12:00")
  end

  it "hides the old grid, shows the skeleton, and blocks taps while busy" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    page.execute_script("document.getElementById('booking-grid').setAttribute('busy', '')")

    expect(page).to have_css("#booking-grid [data-skeleton]", visible: :visible)
    expect(page).to have_no_css("#booking-grid [data-slot]", visible: :visible)
    expect(computed("#booking-grid [data-frame-content]", "opacity")).to eq("0")
    expect(computed("#booking-grid [data-frame-content]", "pointerEvents")).to eq("none")
    expect(page).to fit_the_phone_width
  end

  it "reveals the skeleton only after the delay" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    page.execute_script("document.getElementById('booking-grid').setAttribute('busy', '')")

    expect(computed("#booking-grid [data-frame-content]", "visibility")).to eq("visible")
    expect(computed("#booking-grid [data-skeleton]", "transitionDelay")).to eq("0.15s")
    expect(computed("#booking-grid [data-frame-content]", "transitionDelay")).to eq("0.15s, 0.15s")
  end

  it "drops the loading mark in the same task that inserts the new grid" do
    create(:working_hour, tenant: tenant, professional: professional, weekday: (day + 1).wday, opens_at: "09:00", closes_at: "12:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"
    page.execute_script(<<~JS)
      const frame = document.getElementById("booking-grid")
      new MutationObserver((records, observer) => {
        if (!records.some((record) => record.type === "childList")) return
        frame.dataset.loadingAtInsert = frame.hasAttribute("data-loading")
        observer.disconnect()
      }).observe(frame, { childList: true })
    JS

    find("a[data-day='#{(day + 1).iso8601}']").click

    expect(page).to have_css("turbo-frame#booking-grid[data-loading-at-insert='false']")
  end

  it "keeps the hidden slots out of keyboard reach while busy" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"
    page.execute_script("document.getElementById('booking-grid').setAttribute('busy', '')")
    find("#booking-grid [data-skeleton]", visible: :visible)

    focused = page.evaluate_script(<<~JS)
      (function() {
        const slot = document.querySelector("#booking-grid [data-slot]")
        slot.focus()
        return document.activeElement === slot
      })()
    JS

    expect(focused).to be(false)
  end

  it "keeps the skeleton until the new grid renders, after busy is already gone" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    page.execute_script(<<~JS)
      document.dispatchEvent(new CustomEvent("turbo:before-fetch-request", { detail: { fetchOptions: { headers: { "Turbo-Frame": "booking-grid" } } } }))
    JS

    expect(page).to have_css("turbo-frame#booking-grid[data-loading]:not([busy])")
    expect(page).to have_css("#booking-grid [data-skeleton]", visible: :visible)
    expect(page).to have_no_css("#booking-grid [data-slot]", visible: :visible)
  end

  it "ignores a link prefetch, which never renders" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    page.execute_script(<<~JS)
      document.dispatchEvent(new CustomEvent("turbo:before-fetch-request", { detail: { fetchOptions: { headers: { "X-Sec-Purpose": "prefetch", "Turbo-Frame": "booking-grid" } } } }))
    JS

    expect(page).to have_no_css("turbo-frame#booking-grid[data-loading]")
    expect(page).to have_css("#booking-grid [data-slot]", visible: :visible)
  end

  it "drops the loading mark once the new grid renders" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"
    page.execute_script(<<~JS)
      document.dispatchEvent(new CustomEvent("turbo:before-fetch-request", { detail: { fetchOptions: { headers: { "Turbo-Frame": "booking-grid" } } } }))
    JS
    find("turbo-frame#booking-grid[data-loading]", visible: :all)

    page.execute_script("document.getElementById('booking-grid').dispatchEvent(new CustomEvent('turbo:frame-render', { bubbles: true }))")

    expect(page).to have_no_css("turbo-frame#booking-grid[data-loading]")
    expect(page).to have_css("#booking-grid [data-slot]", visible: :visible)
  end

  it "drops the loading mark when the grid request fails" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"
    page.execute_script(<<~JS)
      document.dispatchEvent(new CustomEvent("turbo:before-fetch-request", { detail: { fetchOptions: { headers: { "Turbo-Frame": "booking-grid" } } } }))
    JS
    find("turbo-frame#booking-grid[data-loading]", visible: :all)

    page.execute_script(<<~JS)
      document.dispatchEvent(new CustomEvent("turbo:fetch-request-error", { detail: { request: { headers: { "Turbo-Frame": "booking-grid" } } } }))
    JS

    expect(page).to have_no_css("turbo-frame#booking-grid[data-loading]")
  end

  it "keeps the skeleton pieces at slot height on a full day" do
    full_day = day + 1
    create(:working_hour, tenant: tenant, professional: professional, weekday: full_day.wday, opens_at: "09:00", closes_at: "18:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: full_day.iso8601)}"

    page.execute_script("document.getElementById('booking-grid').setAttribute('busy', '')")

    expect(page).to have_css("#booking-grid [data-skeleton]", visible: :visible)
    expect(computed("#booking-grid [data-skeleton] > *", "height")).to eq("46px")
  end

  it "keeps the skeleton inside the old content on a day without hours" do
    closed_day = day + 2
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: closed_day.iso8601)}"
    page.execute_script("document.getElementById('booking-grid').setAttribute('busy', '')")
    find("#booking-grid [data-skeleton]", visible: :visible)

    below_hits_skeleton = page.evaluate_script(<<~JS)
      (function() {
        const box = document.querySelector("#booking-grid [data-frame-content]").parentElement.getBoundingClientRect()
        const piece = document.querySelector("#booking-grid [data-skeleton]").lastElementChild.getBoundingClientRect()
        const hit = document.elementFromPoint(piece.left + piece.width / 2, box.bottom + 12)
        return !!(hit && hit.closest("[data-skeleton]"))
      })()
    JS

    expect(below_hits_skeleton).to be(false)
  end

  it "keeps the grid hint spaced below the slots" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    gap = page.evaluate_script(<<~JS)
      document.querySelector("[data-grid-hint]").getBoundingClientRect().top - document.querySelector("[data-slots]").getBoundingClientRect().bottom
    JS

    expect(gap).to eq(10)
  end

  it "keeps the skeleton still under reduced motion" do
    emulate_reduced_motion("reduce")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    page.execute_script("document.getElementById('booking-grid').setAttribute('busy', '')")

    expect(page).to have_css("#booking-grid [data-skeleton]", visible: :visible)
    expect(page).to have_no_css("#booking-grid [data-slot]", visible: :visible)
    expect(computed("#booking-grid [data-skeleton] > *", "animationName")).to eq("none")
  end

  it "uses the tenant neutral token for the skeleton" do
    ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    ze_professional = create(:professional, tenant: ze)
    ze_service = create(:service, tenant: ze, duration_minutes: 45)
    create(:working_hour, tenant: ze, professional: ze_professional, weekday: day.wday, opens_at: "09:00", closes_at: "12:00")
    create(:branding, tenant: ze, brand_600: "#2C6CB0")
    visit "http://#{ze.subdomain}.zubio.com.br#{new_client_service_booking_path(ze_service, day: day.iso8601)}"

    expect(computed_hex("#booking-grid [data-skeleton] > *", "backgroundColor")).to eq("#CFD9E1")
  end

  it "draws the skeleton slots with a visible contrast over the page" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    page.execute_script("document.getElementById('booking-grid').setAttribute('busy', '')")
    find("#booking-grid [data-skeleton]", visible: :visible)

    expect(Branding::ColorScale.new(computed_hex("#booking-grid [data-skeleton] > *", "backgroundColor")).contrast_against(Branding::ColorScale.new("#FFFFFF"))).to be >= 1.2
  end

  it "hides the grid hint while busy" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    page.execute_script("document.getElementById('booking-grid').setAttribute('busy', '')")
    find("#booking-grid [data-skeleton]", visible: :visible)

    expect(computed("#booking-grid [data-grid-hint]", "opacity")).to eq("0")
  end
end
