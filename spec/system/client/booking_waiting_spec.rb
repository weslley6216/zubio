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

  it "does not restore on a normal load" do
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: day.iso8601)}"

    expect(page).to have_css("[data-confirm-bar][disabled]", exact_text: "Confirmar")
  end
end
