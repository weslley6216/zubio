require "rails_helper"

RSpec.describe "My appointments journey", type: :system, js: true do
  let(:tenant) { create(:tenant, subdomain: "mary", name: "Mary Sombracelhas") }
  let(:professional) { create(:professional, tenant: tenant, display_name: "Mary") }
  let(:service) { create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45) }

  before do
    create(:branding, tenant: tenant, brand_600: "#8E4B6B")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "18:00")
  end

  it "goes from the showcase badge to the list, unbooks, and the slot reopens" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    client = create(:client, tenant: tenant, email: "ana@gmail.com", account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
    sign_in_client(client)

    expect(find("[data-my-appointments-badge]").text).to eq("1")

    find("[data-my-appointments-button]").click
    expect(page).to have_css("[data-my-appointment]", text: "Ter, 8 set")
    expect(page).to fit_the_phone_width

    find("[data-my-appointment]").click
    expect(page).to have_text("Seu horário")

    click_link "Desmarcar este horário"
    click_button "Sim, desmarcar"
    expect(page).to have_text("Horário desmarcado")

    visit "http://mary.zubio.com.br#{client_my_appointments_path}"
    expect(page).to have_no_css("[data-my-appointment]")

    visit "http://mary.zubio.com.br#{new_client_service_booking_path(service, day: "2026-09-08")}"
    expect(page).to have_css("[data-slot][data-time='09:45']")
  end

  it "shows the empty state when there is nothing upcoming" do
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    sign_in_client(client)

    visit "http://mary.zubio.com.br#{client_my_appointments_path}"

    expect(page).to have_text("Você não tem horários marcados aqui")
    expect(page).to fit_the_phone_width
  end

  it "signs out back to the establishment" do
    client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
    sign_in_client(client)
    visit "http://mary.zubio.com.br#{client_my_appointments_path}"

    click_button "Sair"

    expect(page).to have_no_css("[data-my-appointments-badge]")
    expect(page).to have_css("[data-my-appointments-button]")
  end

  %w[light dark].each do |scheme|
    it "keeps the list legible in #{scheme}" do
      travel_to Time.zone.local(2026, 9, 8, 7, 0)
      client = create(:client, tenant: tenant, account_linked_at: Time.zone.local(2026, 9, 1, 8, 0))
      create(:appointment, tenant: tenant, professional: professional, service: service, client: client, starts_at: Time.zone.local(2026, 9, 8, 9, 45))
      sign_in_client(client)
      emulate_color_scheme(scheme)

      visit "http://mary.zubio.com.br#{client_my_appointments_path}"

      expect(page).to fit_the_phone_width
      expect(contrast_ratio("[data-my-appointment]")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end
end
