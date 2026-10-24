require "rails_helper"

RSpec.describe "Signing in from the guest receipt", type: :system, js: true do
  it "signs in from the guest receipt and finds the appointment in my appointments" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "mary", name: "Mary Sombracelhas")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: "2026-09-08")}"
    find("[data-slot][data-time='09:45']").click
    fill_in "name", with: "Ana Paula Ribeiro"
    fill_in "phone", with: "11988771234"
    click_button "Confirmar 09:45"
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "g-1", info: { email: "ana@gmail.com", name: "Ana Paula Ribeiro" }
    )

    click_on "Continuar com o Google"
    fill_in "phone", with: "11988771234"
    click_on "Continuar"

    expect(page).to have_css("[data-my-appointment]", text: "Ter, 8 set")
    expect(page).to have_css("[data-my-appointment]", text: "09:45")
    expect(page).to fit_the_phone_width
  end
end
