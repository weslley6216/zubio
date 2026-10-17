require "rails_helper"

RSpec.describe "Public appointment cancellation", type: :system, js: true do
  it "opens the sheet, keeps the appointment when kept, and cancels when confirmed" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "mary", name: "Mary Sombracelhas")
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: Time.zone.local(2026, 9, 8, 9, 45))

    visit "http://mary.zubio.com.br#{client_appointment_path(appointment.cancel_token)}"
    expect(page).to fit_the_phone_width

    click_link "Desmarcar este horário"
    expect(page).to have_text("Desmarcar terça, 8 set, às 09:45?")

    click_button "Manter meu horário"
    expect(page).to have_text("Seu horário")
    expect(page).to have_no_text("Desmarcar terça, 8 set, às 09:45?")
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_confirmed

    click_link "Desmarcar este horário"
    click_button "Sim, desmarcar"
    expect(page).to have_text("Horário desmarcado")
    expect(page).to fit_the_phone_width
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_cancelled
  end
end
