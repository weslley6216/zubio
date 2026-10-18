require "rails_helper"

RSpec.describe "Owner appointment cancellation", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, :with_professional, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }
  let(:professional) { owner.professional }

  it "cancels the appointment and redirects to its detail" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    post owner_appointment_cancellation_path(appointment)

    expect(response).to redirect_to(owner_appointment_path(appointment))
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_cancelled
  end

  it "frees the 09:45 slot back onto the booking grid" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    post owner_appointment_cancellation_path(appointment)

    get new_client_service_booking_path(service, day: "2026-09-08")
    expect(Nokogiri::HTML5(response.body).css("[data-slots] [data-slot]").map { |slot| slot.text.strip }).to include("09:45")
  end

  it "keeps the cancelled appointment listed and struck through on the reloaded agenda" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    post owner_appointment_cancellation_path(appointment)

    get owner_appointments_path(day: "2026-09-08")
    expect(Nokogiri::HTML5(response.body).css("turbo-frame#agenda_day main .line-through").map { |node| node.text.strip }).to include("Ana Paula Ribeiro")
    expect(response.body).to include("Desmarcado")
  end

  it "keeps an already cancelled appointment cancelled on a forged post" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    post owner_appointment_cancellation_path(appointment)

    expect(response).to redirect_to(owner_appointment_path(appointment))
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_cancelled
  end

  it "keeps a past appointment confirmed on a forged post" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 7, 9, 45)) }
    sign_in_owner(owner)

    post owner_appointment_cancellation_path(appointment)

    expect(response).to redirect_to(owner_appointment_path(appointment))
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_confirmed
  end

  it "sends an anonymous visitor to the login and keeps the appointment confirmed" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    host! "#{tenant.subdomain}.zubio.com.br"

    post owner_appointment_cancellation_path(appointment)

    expect(response).to redirect_to(new_owner_session_path)
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_confirmed
  end

  it "answers not found for another establishment's appointment and keeps it confirmed" do
    ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    ze_professional = create(:professional, tenant: ze)
    ze_service = create(:service, tenant: ze)
    ze_client = create(:client, tenant: ze)
    ze_appointment = ActsAsTenant.with_tenant(ze) { create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, client: ze_client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    post owner_appointment_cancellation_path(ze_appointment)

    expect(response).to have_http_status(:not_found)
    expect(ActsAsTenant.with_tenant(ze) { ze_appointment.reload }).to be_confirmed
  end

  it "answers not found for an unknown appointment" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    post "/owner/appointments/0/cancellation"

    expect(response).to have_http_status(:not_found)
  end
end
