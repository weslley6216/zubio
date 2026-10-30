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
    expect(page).to fit_the_phone_width
  end

  it "reflects a client cancellation on the open agenda without reloading" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(professional_user)

    ActsAsTenant.with_tenant(tenant) { appointment.cancel! }

    expect(page).to have_text("1 desmarcado")
    expect(page).to have_no_css(".line-through", text: "Ana Paula Ribeiro")
    expect(page).to fit_the_phone_width
  end

  it "keeps the open cancellations group open across a live refresh" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    cancelled_client = create(:client, tenant: tenant, name: "Bruna Salles")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, :cancelled, tenant: tenant, professional: professional_user.professional, service: service, client: cancelled_client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(professional_user)
    find("summary", text: "desmarcado").click
    expect(page).to have_css("details[open]")

    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: create(:client, tenant: tenant, name: "Ana Paula Ribeiro"), starts_at: Time.zone.local(2026, 9, 8, 11, 0)) }

    expect(page).to have_text("Ana Paula Ribeiro")
    expect(page).to have_css("details[open]")
  end

  it "leaves the open day untouched when a booking lands on another day" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    wednesday = Date.current + 1
    sign_in_owner(professional_user)

    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: create(:client, tenant: tenant, name: "Bruna Salles"), starts_at: wednesday.in_time_zone.change(hour: 9, min: 45)) }
    sleep 0.3

    expect(page).to have_no_text("Bruna Salles")
  end

  it "shows an appointment from another day once the owner switches to it" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    wednesday = Date.current + 1
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: create(:client, tenant: tenant, name: "Bruna Salles"), starts_at: wednesday.in_time_zone.change(hour: 9, min: 45)) }
    sign_in_owner(professional_user)

    find("[data-day='#{wednesday.iso8601}']").click

    expect(page).to have_text("Bruna Salles")
  end

  it "keeps the open detail on the same appointment with fresh data across a live refresh" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    appointment = ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    sign_in_owner(professional_user)
    click_on "Ana Paula Ribeiro"
    find("turbo-frame#appointment_detail section", text: "Ana Paula Ribeiro")

    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: create(:client, tenant: tenant, name: "Bruna Salles"), starts_at: Time.zone.local(2026, 9, 8, 11, 0)) }

    expect(page).to have_text("Bruna Salles")
    expect(page).to have_css("turbo-frame#appointment_detail section", text: "Ana Paula Ribeiro")
    expect(page).to have_current_path(owner_appointment_path(appointment))
    expect(page).to fit_the_phone_width
  end

  it "updates a second open device without reloading" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    sign_in_owner(professional_user)
    using_session(:second_device) { sign_in_owner(professional_user) }

    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: create(:client, tenant: tenant, name: "Ana Paula Ribeiro"), starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }

    expect(page).to have_text("Ana Paula Ribeiro")
    using_session(:second_device) { expect(page).to have_text("Ana Paula Ribeiro") }
  end

  it "catches up with what changed while hidden when the page becomes visible again" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    sign_in_owner(professional_user)
    Appointment.suppressing_turbo_broadcasts do
      ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45)) }
    end

    page.execute_script('document.dispatchEvent(new Event("visibilitychange"))')

    expect(page).to have_text("Ana Paula Ribeiro")
  end
end
