require "rails_helper"

RSpec.describe "Owner agenda live updates", type: :system, js: true, cable: true do
  it "shows a new booking on the open agenda without reloading" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    create(:working_hour, tenant: tenant, professional: professional_user.professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    sign_in_owner(professional_user)

    using_session(:client) do
      visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: "2026-09-08")}"
      find("[data-slot][data-time='09:45']").click
      fill_in "name", with: "Ana Paula Ribeiro"
      fill_in "phone", with: "11988771234"
      click_button "Confirmar 09:45"
      expect(page).to have_text("Horário confirmado")
    end

    expect(page).to have_text("Ana Paula Ribeiro")
  end
end
