require "rails_helper"

RSpec.describe "Owner appointment completion", type: :request do
  let(:tenant) { create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora") }
  let(:owner) { create(:user, :with_professional, tenant: tenant, name: "Ana Lima", email: "ana@example.com", password: "s3cr3t123") }
  let(:professional) { owner.professional }

  it "completes the past appointment and redirects to its detail" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    post owner_appointment_completion_path(appointment)

    expect(response).to redirect_to(owner_appointment_path(appointment))
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_completed
  end

  it "shows the completed badge on the reloaded agenda" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)
    post owner_appointment_completion_path(appointment)

    get owner_appointments_path(day: "2026-09-08")

    expect(Nokogiri::HTML5(response.body).css("turbo-frame#agenda_day main [data-appointment-id='#{appointment.id}']").text).to include("Concluído")
  end

  it "corrects a no-show to completed" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, :no_show, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    post owner_appointment_completion_path(appointment)

    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_completed
  end

  it "keeps a future appointment confirmed on a forged completion" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    post owner_appointment_completion_path(appointment)

    expect(response).to redirect_to(owner_appointment_path(appointment))
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_confirmed
  end

  it "keeps a cancelled appointment cancelled on a forged completion" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(owner)

    post owner_appointment_completion_path(appointment)

    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_cancelled
  end

  it "sends an anonymous visitor to the login and keeps the appointment confirmed" do
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    create(:branding, tenant: tenant)
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    host! "#{tenant.subdomain}.zubio.com.br"

    post owner_appointment_completion_path(appointment)

    expect(response).to redirect_to(new_owner_session_path)
    expect(ActsAsTenant.with_tenant(tenant) { appointment.reload }).to be_confirmed
  end

  it "answers not found for another establishment's appointment and keeps it confirmed" do
    ze = create(:tenant, subdomain: "barbearia-do-ze", name: "Barbearia do Zé")
    ze_professional = create(:professional, tenant: ze)
    ze_service = create(:service, tenant: ze)
    ze_client = create(:client, tenant: ze)
    ze_appointment = ActsAsTenant.with_tenant(ze) { create(:appointment, tenant: ze, professional: ze_professional, service: ze_service, client: ze_client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    travel_to Time.zone.local(2026, 9, 8, 19, 0)
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    post owner_appointment_completion_path(ze_appointment)

    expect(response).to have_http_status(:not_found)
    expect(ActsAsTenant.with_tenant(ze) { ze_appointment.reload }).to be_confirmed
  end

  it "answers not found for an unknown appointment" do
    create(:branding, tenant: tenant)
    sign_in_owner(owner)

    post "/owner/appointments/0/completion"

    expect(response).to have_http_status(:not_found)
  end
end
