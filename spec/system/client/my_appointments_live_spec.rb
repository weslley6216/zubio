require "rails_helper"

RSpec.describe "Client appointments live updates", type: :system, js: true, cable: true do
  it "drops a cancelled appointment from the client's list without reloading when the owner cancels" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
    sign_in_client(client)
    visit "http://#{tenant.subdomain}.zubio.com.br#{client_my_appointments_path}"
    expect(page).to have_css("turbo-cable-stream-source[connected]", visible: :all)

    ActsAsTenant.with_tenant(tenant) { appointment.cancel! }

    expect(page).to have_text("Você não tem horários marcados aqui")
    expect(page).to fit_the_phone_width
  end
end
