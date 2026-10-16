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

  it "carries the picked day into the confirmation bar" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 45, price_cents: 6_000)
    [ 2, 4 ].each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "12:00") }
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service)}"

    find("[data-day='2026-09-10']").click

    expect(page).to have_css("[data-summary]", exact_text: "Qui, 10 set · R$ 60")
  end

  it "pins the confirmation bar to the bottom of a short screen" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 180)
    create(:working_hour, tenant: tenant, professional: professional, weekday: Date.current.next_week(:tuesday).wday, opens_at: "09:00", closes_at: "12:00")

    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: Date.current.next_week(:tuesday).iso8601)}"

    expect(page).to have_css("[data-slots] [data-slot]", count: 1)
    expect(page.evaluate_script("Math.round(document.querySelector('[data-confirm-bar]').parentElement.getBoundingClientRect().bottom)")).to eq(page.evaluate_script("window.innerHeight"))
  end

  it "shows four days at a time on the phone, each a touch target" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 60)
    (0..6).each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "18:00") }

    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service)}"

    expect(page.evaluate_script(<<~JS)).to eq(4)
      (() => {
        const strip = document.querySelector('[data-day-selector]').getBoundingClientRect();
        return [...document.querySelectorAll('[data-day-selector] [data-day]')]
          .filter((day) => { const box = day.getBoundingClientRect(); return box.left >= strip.left && box.right <= strip.right + 0.5; }).length;
      })()
    JS
    expect(page.evaluate_script("document.querySelector('[data-slots] [data-slot]').getBoundingClientRect().height")).to be >= 44
  end

  it "fits two weeks of days inside the phone screen" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 60)
    (0..6).each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "18:00") }

    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service)}"

    expect(page).to have_css("[data-day-selector] [data-day]", count: 14)
    expect(page).to fit_the_phone_width
  end

  it "keeps the day picked at the end of the strip in view" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 60)
    (0..6).each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "18:00") }
    last_day = Date.current + 13
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service)}"
    page.execute_script("document.querySelector('[data-day-selector]').scrollLeft = 10000")

    find("[data-day='#{last_day.iso8601}']").click

    expect(page).to have_css("[data-day='#{last_day.iso8601}'][aria-current='date']")
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const strip = document.querySelector('[data-day-selector]').getBoundingClientRect();
        const day = document.querySelector('[aria-current=date]').getBoundingClientRect();
        return day.left >= strip.left && day.right <= strip.right;
      })()
    JS
  end

  it "lays both weeks out without sideways scrolling on a desktop" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, duration_minutes: 60)
    (0..6).each { |weekday| create(:working_hour, tenant: tenant, professional: professional, weekday: weekday, opens_at: "09:00", closes_at: "18:00") }
    emulate_desktop_screen(width: 1280, height: 800)

    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service)}"

    expect(page).to have_css("[data-day-selector] [data-day]", count: 14)
    expect(page.evaluate_script(<<~JS)).to be(true)
      (() => {
        const strip = document.querySelector('[data-day-selector]');
        const column = strip.closest('main').querySelector('[data-slots]').getBoundingClientRect();
        const box = strip.getBoundingClientRect();
        return strip.scrollWidth <= strip.clientWidth && box.left >= column.left && box.right <= column.right;
      })()
    JS
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
      expect(opaque?("[data-slot]")).to be(true)
      expect(contrast_ratio("[data-slot]")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(opaque?("[data-day][aria-disabled='true']")).to be(true)
      expect(opaque?("[data-price]")).to be(true)
      expect(contrast_ratio("[data-price]")).to be >= Branding::ColorScale::MIN_CONTRAST
      expect(opaque?("[data-confirm-bar]")).to be(true)
      expect(contrast_ratio("[data-confirm-bar]")).to be >= Branding::ColorScale::MIN_NON_TEXT_CONTRAST
    end
  end

  it "enables the confirm button and names the time once a slot is picked" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")

    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: "2026-09-08")}"
    find("[data-slot][data-time='09:45']").click

    expect(page).to have_css("[data-confirm-bar]:not([disabled])", text: "Confirmar 09:45")
    expect(page).to have_css("[data-summary]", text: "09:45")
  end

  it "keeps the name and phone when the booking comes back with a field error" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant, display_name: "Mary")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "12:00")

    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: "2026-09-08")}"
    find("[data-slot][data-time='09:45']").click
    fill_in "name", with: "Ana Paula Ribeiro"
    fill_in "phone", with: "1198877"
    click_button "Confirmar 09:45"

    expect(page).to have_css("[data-field='phone'] .text-danger")
    expect(page).to have_field("name", with: "Ana Paula Ribeiro")
    expect(page).to have_field("phone", with: "1198877")
    expect(page).to have_css("[data-slot][data-time='09:45'][aria-pressed='true']")
  end
end
