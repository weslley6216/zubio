require "rails_helper"

RSpec.describe "Public booking interaction", type: :system, js: true do
  it "swaps the day's grid without reloading the page" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    wednesday = tuesday + 1
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "14:00", closes_at: "16:00")

    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    page.execute_script("window.__noReload = true")
    find("[data-day='#{wednesday.iso8601}']").click

    expect(page).to have_css("[data-day='#{wednesday.iso8601}'][aria-current='date']")
    expect(page.all("[data-slots] [data-slot]").map(&:text)).to eq([ "14:00", "15:00" ])
    expect(page.evaluate_script("window.__noReload")).to be(true)
  end

  %w[light dark].each do |scheme|
    it "keeps the booking screen readable in #{scheme}" do
      tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      professional = create(:professional, tenant: tenant)
      service = create(:service, tenant: tenant, duration_minutes: 45)
      tuesday = Date.current.next_week(:tuesday)
      create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")
      emulate_color_scheme(scheme)

      visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"

      expect(opaque?("header")).to be(true)
      expect(contrast_ratio("header")).to be >= Branding::ColorScale::MIN_CONTRAST
    end
  end
end
