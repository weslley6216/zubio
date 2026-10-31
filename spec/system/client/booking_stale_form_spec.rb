require "rails_helper"

RSpec.describe "Client booking with a stale form", type: :system, js: true do
  around do |example|
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  it "keeps the chosen time and asks to confirm again when the session changed while the page was open" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    find("[data-slot][data-time='10:00']").click
    fill_in "name", with: "Ana Paula Ribeiro"
    fill_in "phone", with: "11988771234"
    page.execute_script("document.querySelector(\"input[name='authenticity_token']\").value = 'stale'")

    click_button "Confirmar 10:00"

    expect(page).to have_css("[role='status']", text: "A página ficou desatualizada. Confira o horário e confirme de novo.")
    expect(page).to have_css("[data-slot][data-time='10:00'][aria-pressed='true']")
    expect(page).to have_field("name", with: "Ana Paula Ribeiro")
    expect(page).to fit_the_phone_width
  end

  it "books on the second confirm after the stale form came back" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    find("[data-slot][data-time='10:00']").click
    fill_in "name", with: "Ana Paula Ribeiro"
    fill_in "phone", with: "11988771234"
    page.execute_script("document.querySelector(\"input[name='authenticity_token']\").value = 'stale'")
    click_button "Confirmar 10:00"
    find("[role='status']", text: "A página ficou desatualizada.")

    click_button "Confirmar 10:00"

    expect(page).to have_text("Horário confirmado")
  end
end
