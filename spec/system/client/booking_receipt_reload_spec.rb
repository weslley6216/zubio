require "rails_helper"

RSpec.describe "Client booking receipt on reload", type: :system, js: true do
  it "shows the receipt again when the browser reopens its address" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    find("[data-slot][data-time='10:00']").click
    fill_in "name", with: "Ana Paula Ribeiro"
    fill_in "phone", with: "11988771234"
    click_button "Confirmar 10:00"
    find("[data-receipt]")

    visit page.current_url

    expect(page).to have_text("Horário confirmado")
    expect(page).to fit_the_phone_width
  end

  it "returns to the booking page when the browser reopens the address of a refused confirm" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    find("[data-slot][data-time='10:00']").click
    fill_in "phone", with: "11988771234"
    click_button "Confirmar 10:00"
    find("[data-confirm-bar]")

    visit page.current_url

    expect(page).to have_css("[data-slots]")
    expect(page).to have_current_path(new_client_service_booking_path(service))
  end
end
