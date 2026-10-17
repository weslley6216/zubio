require "rails_helper"

RSpec.describe "Public appointment cancellation", type: :request do
  let(:tenant) { create(:tenant, subdomain: "mary", name: "Mary Sombracelhas") }

  it "shows the confirmation text and both choices" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    appointment = create(:appointment, tenant: tenant, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
    host! "mary.zubio.com.br"

    get new_client_cancellation_path(appointment.cancel_token)

    expect(response.body).to include("Desmarcar terça, 8 set, às 09:45?")
    expect(response.body).to include("O horário volta a ficar livre para outras pessoas. Não dá para desfazer.")
    expect(response.body).to include("Sim, desmarcar")
    expect(response.body).to include("Manter meu horário")
  end

  it "redirects a confirmation request for a non-cancellable appointment to the appointment" do
    appointment = create(:appointment, :cancelled, tenant: tenant)
    host! "mary.zubio.com.br"

    get new_client_cancellation_path(appointment.cancel_token)

    expect(response).to redirect_to(client_appointment_path(appointment.cancel_token))
  end

  it "cancels the appointment and redirects to it" do
    appointment = create(:appointment, tenant: tenant)
    host! "mary.zubio.com.br"

    post client_cancellation_path(appointment.cancel_token)

    expect(response).to redirect_to(client_appointment_path(appointment.cancel_token))
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_cancelled
  end

  it "shows the cancelled screen after following the redirect" do
    appointment = create(:appointment, tenant: tenant)
    host! "mary.zubio.com.br"

    post client_cancellation_path(appointment.cancel_token)
    follow_redirect!

    expect(response.body).to include("Horário desmarcado")
  end

  it "frees the slot back onto the grid after cancelling" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    appointment = create(:appointment, tenant: tenant, professional: professional, service: service, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
    host! "mary.zubio.com.br"

    post client_cancellation_path(appointment.cancel_token)

    get new_client_service_booking_path(service, day: "2026-09-08")
    expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to include("09:45")
  end

  it "does not re-cancel an already cancelled appointment on a forged post" do
    appointment = create(:appointment, :cancelled, tenant: tenant)
    host! "mary.zubio.com.br"

    post client_cancellation_path(appointment.cancel_token)

    expect(response).to redirect_to(client_appointment_path(appointment.cancel_token))
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_cancelled
  end

  it "answers not found for a cancellation post with an unknown token" do
    host! "mary.zubio.com.br"

    post "/a/does-not-exist/cancellation"

    expect(response).to have_http_status(:not_found)
  end

  it "keeps the token out of the redirect log" do
    appointment = create(:appointment, tenant: tenant)
    host! "mary.zubio.com.br"

    log = capture_request_log { post client_cancellation_path(appointment.cancel_token) }

    expect(log).not_to include(appointment.cancel_token)
  end
end
