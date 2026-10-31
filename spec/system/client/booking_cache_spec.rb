require "rails_helper"

RSpec.describe "Public booking day cache", type: :system, js: true do
  it "shows the preloaded neighbour's times without the skeleton" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    wednesday = tuesday + 1
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "14:00", closes_at: "16:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    wait_until { page.driver.network_traffic.any? { |exchange| exchange.url&.include?("day=#{wednesday.iso8601}") && exchange.finished? } }
    watch_skeleton("booking-grid")

    find("a[data-day='#{wednesday.iso8601}']").click

    expect(page).to have_css("[data-slots] [data-slot]", count: 2)
    expect(page.all("[data-slots] [data-slot]").map(&:text)).to eq([ "14:00", "15:00" ])
    expect(skeleton_peak).to eq(0)
    expect(page).to fit_the_phone_width
  end

  it "returns to a seen day without the skeleton" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    wednesday = tuesday + 1
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "14:00", closes_at: "16:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    find("a[data-day='#{wednesday.iso8601}']").click
    expect(page.all("[data-slots] [data-slot]").map(&:text)).to eq([ "14:00", "15:00" ])
    watch_skeleton("booking-grid")

    find("a[data-day='#{tuesday.iso8601}']").click

    expect(page).to have_css("[data-slots] [data-slot]", count: 2)
    expect(page.all("[data-slots] [data-slot]").map(&:text)).to eq([ "09:00", "10:00" ])
    expect(skeleton_peak).to eq(0)
  end

  it "shows the cached grid at once and then strikes the time taken afterwards" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    wednesday = tuesday + 1
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "14:00", closes_at: "16:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    wait_until { page.driver.network_traffic.any? { |exchange| exchange.url&.include?("day=#{wednesday.iso8601}") && exchange.finished? } }
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: create(:client, tenant: tenant), starts_at: wednesday.in_time_zone.change(hour: 14)) }

    find("a[data-day='#{wednesday.iso8601}']").click

    Capybara.using_wait_time(5) { expect(page).to have_css("[data-slot-taken]", text: "14:00") }
    expect(page.all("[data-slots] [data-slot]").map(&:text)).to eq([ "15:00" ])
  end

  it "reveals a visible slot skeleton when an unloaded day is slow" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    far_tuesday = tuesday + 7
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    held = []
    page.driver.browser.on(:request) { |request| request.url.include?("day=#{far_tuesday.iso8601}") ? held << request : request.continue }
    page.driver.browser.network.intercept(pattern: "*/booking/new*")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"

    find("a[data-day='#{far_tuesday.iso8601}']").click

    expect(page).to have_css("#booking-grid [data-skeleton]", visible: :visible)
    expect(page).to fit_the_phone_width
    held.each(&:continue)
  end

  it "clears the chosen time and warns when the revalidation finds it taken" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    wednesday = tuesday + 1
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "14:00", closes_at: "16:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    wait_until { page.driver.network_traffic.any? { |exchange| exchange.url&.include?("day=#{wednesday.iso8601}") && exchange.finished? } }
    held = []
    page.driver.browser.on(:request) { |request| request.url.include?("day=#{wednesday.iso8601}") ? held << request : request.continue }
    page.driver.browser.network.intercept(pattern: "*/booking/new*")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: create(:client, tenant: tenant), starts_at: wednesday.in_time_zone.change(hour: 14)) }
    find("a[data-day='#{wednesday.iso8601}']").click
    find("[data-slot][data-time='14:00']").click
    wait_until { held.any? }

    held.each(&:continue)

    Capybara.using_wait_time(5) { expect(page).to have_css("[data-slot-taken]", text: "14:00") }
    expect(page).to have_css("[data-slot-taken-notice]", visible: :visible, text: "Esse horário acabou de ser ocupado. Escolha outro.")
    expect(page).to have_css("[data-confirm-bar][disabled]", exact_text: "Confirmar")
    expect(find("input[name='starts_at']", visible: :hidden).value).to eq("")
  end

  it "keeps the chosen time pressed when the revalidation still offers it" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    wednesday = tuesday + 1
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "14:00", closes_at: "16:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    wait_until { page.driver.network_traffic.any? { |exchange| exchange.url&.include?("day=#{wednesday.iso8601}") && exchange.finished? } }
    held = []
    page.driver.browser.on(:request) { |request| request.url.include?("day=#{wednesday.iso8601}") ? held << request : request.continue }
    page.driver.browser.network.intercept(pattern: "*/booking/new*")
    find("a[data-day='#{wednesday.iso8601}']").click
    find("[data-slot][data-time='14:00']").click
    wait_until { held.any? }

    held.each(&:continue)
    wait_until { page.driver.network_traffic.count { |exchange| exchange.url&.include?("day=#{wednesday.iso8601}") && exchange.finished? } >= 2 }

    expect(page).to have_css("[data-slot][data-time='14:00'][aria-pressed='true']")
    expect(page).to have_css("[data-confirm-bar]:not([disabled])", text: "Confirmar")
    expect(page).to have_no_css("[data-slot-taken-notice]", visible: :visible)
  end

  it "hides the warning once another time is chosen" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional = create(:professional, tenant: tenant)
    service = create(:service, tenant: tenant, name: "Corte", duration_minutes: 60)
    tuesday = Date.current.next_week(:tuesday)
    wednesday = tuesday + 1
    create(:working_hour, tenant: tenant, professional: professional, weekday: 2, opens_at: "09:00", closes_at: "11:00")
    create(:working_hour, tenant: tenant, professional: professional, weekday: 3, opens_at: "14:00", closes_at: "16:00")
    visit "http://#{tenant.subdomain}.zubio.com.br#{new_client_service_booking_path(service, day: tuesday.iso8601)}"
    wait_until { page.driver.network_traffic.any? { |exchange| exchange.url&.include?("day=#{wednesday.iso8601}") && exchange.finished? } }
    held = []
    page.driver.browser.on(:request) { |request| request.url.include?("day=#{wednesday.iso8601}") ? held << request : request.continue }
    page.driver.browser.network.intercept(pattern: "*/booking/new*")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional, service: service, client: create(:client, tenant: tenant), starts_at: wednesday.in_time_zone.change(hour: 14)) }
    find("a[data-day='#{wednesday.iso8601}']").click
    find("[data-slot][data-time='14:00']").click
    wait_until { held.any? }
    held.each(&:continue)
    Capybara.using_wait_time(5) { expect(page).to have_css("[data-slot-taken-notice]", visible: :visible) }

    find("[data-slot][data-time='15:00']").click

    expect(page).to have_no_css("[data-slot-taken-notice]", visible: :visible)
    expect(page).to have_css("[data-confirm-bar]", text: "Confirmar 15:00")
  end
end
