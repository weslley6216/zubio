require "rails_helper"

RSpec.describe "Public booking receipt", type: :request do
  let(:tenant) { create(:tenant, subdomain: "mary", name: "Mary Sombracelhas") }

  it "shows the receipt of a confirmed appointment by its token" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: Time.zone.local(2026, 9, 8, 9, 0))
    host! "mary.zubio.com.br"

    get client_receipt_path(appointment.cancel_token)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Horário confirmado")
    expect(response.body).to include("Ter, 8 set · 09:00")
    expect(response.body).to include("Design de sobrancelhas")
  end

  it "sends a cancelled appointment to its appointment screen instead of a confirmed receipt" do
    appointment = create(:appointment, tenant: tenant, status: :cancelled)
    host! "mary.zubio.com.br"

    get client_receipt_path(appointment.cancel_token)

    expect(response).to redirect_to(client_appointment_path(appointment.cancel_token))
  end

  it "answers not found for an unknown token" do
    host! "mary.zubio.com.br"

    get client_receipt_path("unknown-token")

    expect(response).to have_http_status(:not_found)
  end

  it "answers not found for another establishment's token, with none of its data" do
    ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    ze_service = create(:service, tenant: ze, name: "Barba do Zé")
    ze_appointment = create(:appointment, tenant: ze, service: ze_service, professional: create(:professional, tenant: ze))
    host! "mary.zubio.com.br"

    get client_receipt_path(ze_appointment.cancel_token)

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Barba do Zé")
  end
end
