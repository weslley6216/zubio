require "rails_helper"

RSpec.describe "Public appointment screen", type: :request do
  let(:tenant) { create(:tenant, subdomain: "mary", name: "Mary Sombracelhas") }

  it "shows the day, time and service and offers to cancel" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45, price_cents: 6_000)
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
    host! "mary.zubio.com.br"

    get client_appointment_path(appointment.cancel_token)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Seu horário")
    expect(response.body).to include("Ter, 8 set · 09:45")
    expect(response.body).to include("Design de sobrancelhas")
    expect(response.body).to include("R$ 60,00")
    expect(response.body).to include("Este link mostra só este agendamento.")
    expect(response.body).to include("Marcar outro horário")
    expect(response.body).to include("Desmarcar este horário")
  end

  it "does not change the appointment on a read" do
    appointment = create(:appointment, tenant: tenant)
    host! "mary.zubio.com.br"

    get client_appointment_path(appointment.cancel_token)

    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_confirmed
  end

  it "shows the cancelled screen without a way to cancel for an already cancelled appointment" do
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    appointment = create(:appointment, :cancelled, tenant: tenant, professional: professional)
    host! "mary.zubio.com.br"

    get client_appointment_path(appointment.cancel_token)

    expect(response.body).to include("Horário desmarcado")
    expect(response.body).not_to include("Desmarcar este horário")
  end

  it "shows a past appointment without a way to cancel" do
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas")
    appointment = create(:appointment, :past, tenant: tenant, service: service)
    host! "mary.zubio.com.br"

    get client_appointment_path(appointment.cancel_token)

    expect(response.body).to include("Design de sobrancelhas")
    expect(response.body).not_to include("Desmarcar este horário")
  end

  it "answers not found for a token that matches no appointment, revealing nothing" do
    professional = create(:professional, tenant: tenant, display_name: "Mary Sombracelhas")
    create(:appointment, tenant: tenant, professional: professional)
    host! "mary.zubio.com.br"

    get "/a/does-not-exist"

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Mary Sombracelhas")
  end

  it "answers not found for a token of another tenant, revealing none of its data" do
    aurora = create(:tenant, subdomain: "aurora", name: "Estúdio Aurora")
    aurora_service = create(:service, tenant: aurora, name: "Corte Aurora")
    aurora_appointment = create(:appointment, tenant: aurora, service: aurora_service)
    host! "mary.zubio.com.br"

    get client_appointment_path(aurora_appointment.cancel_token)

    expect(response).to have_http_status(:not_found)
    expect(response.body).not_to include("Estúdio Aurora")
    expect(response.body).not_to include("Corte Aurora")
  end

  it "keeps the token out of the request log" do
    appointment = create(:appointment, tenant: tenant)
    host! "mary.zubio.com.br"

    log = capture_request_log { get client_appointment_path(appointment.cancel_token) }

    expect(log).not_to include(appointment.cancel_token)
    expect(log).to include("/a/[FILTERED]")
  end
end
