require "rails_helper"

RSpec.describe "Owner books a new appointment", type: :system, js: true do
  it "fits a 390px phone without horizontal scroll" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Mary Sombracelhas")
    owner = create(:user, :with_professional, tenant: tenant, name: "Mary Sombracelhas", email: "mary@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    service = create(:service, tenant: tenant, name: "Design com henna", duration_minutes: 60)
    create(:working_hour, tenant: tenant, professional: owner.professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: owner.professional, service: service, starts_at: Date.new(2026, 9, 8).in_time_zone.change(hour: 10)) }
    emulate_phone
    sign_in_owner(owner)

    visit new_owner_appointment_url(host: "#{tenant.subdomain}.zubio.com.br", service_id: service.id)

    expect(page).to fit_the_phone_width
  end

  it "finds the existing client by phone and marks today at the chosen time" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Mary Sombracelhas")
    owner = create(:user, :with_professional, tenant: tenant, name: "Mary Sombracelhas", email: "mary@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    service = create(:service, tenant: tenant, name: "Design com henna", duration_minutes: 60)
    create(:working_hour, tenant: tenant, professional: owner.professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    client = create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: owner.professional, service: service, starts_at: Date.new(2026, 9, 8).in_time_zone.change(hour: 10)) }
    emulate_phone
    sign_in_owner(owner)
    visit new_owner_appointment_url(host: "#{tenant.subdomain}.zubio.com.br", service_id: service.id)

    fill_in "phone", with: "11 99123"

    expect(page).to have_content("Juliana Prado")
    expect(page).to have_content("já é sua cliente")
    find("[data-client-id='#{client.id}']").click

    expect(page).to have_select("service_id", selected: "Design com henna · 60 min")
    find("[data-slot][data-time='11:00']").click

    expect(page).to have_css("[data-slot-selector-target='submit']:not([disabled])", text: "Marcar hoje às 11:00")
    click_button "Marcar hoje às 11:00"

    expect(page).to have_content("11:00")
  end

  it "offers 'Cliente nova com este telefone' for an unknown number and asks the name" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Mary Sombracelhas")
    owner = create(:user, :with_professional, tenant: tenant, name: "Mary Sombracelhas", email: "mary@example.com", password: "s3cr3t123")
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    service = create(:service, tenant: tenant, name: "Design com henna", duration_minutes: 60)
    create(:working_hour, tenant: tenant, professional: owner.professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
    create(:client, tenant: tenant, name: "Juliana Prado", phone: "11991234455")
    emulate_phone
    sign_in_owner(owner)
    visit new_owner_appointment_url(host: "#{tenant.subdomain}.zubio.com.br", service_id: service.id)

    fill_in "phone", with: "11 90000"

    expect(page).to have_content("Cliente nova com este telefone")
    expect(page).to have_field("name")
  end
end
