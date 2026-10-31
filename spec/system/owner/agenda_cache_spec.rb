require "rails_helper"

RSpec.describe "Owner agenda day cache", type: :system, js: true do
  it "shows the preloaded neighbour's appointment without the skeleton" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Bruna Salles")
    tomorrow = Date.current + 1
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: tomorrow.in_time_zone.change(hour: 10, min: 40)) }
    sign_in_owner(professional_user)
    wait_until { page.driver.network_traffic.any? { |exchange| exchange.url&.include?("day=#{tomorrow.iso8601}") && exchange.finished? } }
    watch_skeleton("agenda_day")

    find("[data-day='#{tomorrow.iso8601}']").click

    expect(page).to have_text("Bruna Salles")
    expect(page).to have_text("10:40")
    expect(skeleton_peak).to eq(0)
  end

  it "returns to a seen day without the skeleton" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    today = Date.current
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: today.in_time_zone.change(hour: 9)) }
    sign_in_owner(professional_user)
    tomorrow = today + 1
    find("[data-day='#{tomorrow.iso8601}']").click
    expect(page).to have_no_text("Ana Paula Ribeiro")
    watch_skeleton("agenda_day")

    find("[data-day='#{today.iso8601}']").click

    expect(page).to have_text("Ana Paula Ribeiro")
    expect(skeleton_peak).to eq(0)
  end

  it "does not duplicate the fetch when the tap catches an inflight preload" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    tomorrow = Date.current + 1
    held = []
    page.driver.browser.on(:request) { |request| request.url.include?("day=#{tomorrow.iso8601}") ? held << request : request.continue }
    page.driver.browser.network.intercept(pattern: "*/owner/appointments*")
    sign_in_owner(professional_user)
    wait_until { held.any? }

    find("[data-day='#{tomorrow.iso8601}']").click
    held.each(&:continue)

    expect(page).to have_css("[data-day='#{tomorrow.iso8601}'][aria-current]")
    expect(page.driver.network_traffic.count { |exchange| exchange.url&.include?("day=#{tomorrow.iso8601}") }).to eq(1)
  end

  it "shows the empty day at once and then the appointment booked afterwards" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    tomorrow = Date.current + 1
    sign_in_owner(professional_user)
    wait_until { page.driver.network_traffic.any? { |exchange| exchange.url&.include?("day=#{tomorrow.iso8601}") && exchange.finished? } }
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: create(:client, tenant: tenant, name: "Bruna Salles"), starts_at: tomorrow.in_time_zone.change(hour: 11)) }

    find("[data-day='#{tomorrow.iso8601}']").click

    expect(page).to have_text("Bruna Salles")
  end

  it "keeps the open row marked after the revalidation" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    today = Date.current
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: today.in_time_zone.change(hour: 9)) }
    tomorrow = today + 1
    sign_in_owner(professional_user)
    find("[data-day='#{tomorrow.iso8601}']").click
    expect(page).to have_no_text("Ana Paula Ribeiro")
    held = []
    page.driver.browser.on(:request) { |request| request.url.include?("day=#{today.iso8601}") ? held << request : request.continue }
    page.driver.browser.network.intercept(pattern: "*/owner/appointments*")

    find("[data-day='#{today.iso8601}']").click
    wait_until { held.any? }
    click_on "Ana Paula Ribeiro"
    find_link("Chamar no WhatsApp")
    held.each(&:continue)

    expect(page).to have_css("#agenda_day [data-appointment-id] a[aria-current='true']")
  end

  it "lists among the cancelled the appointment the owner cancelled" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro")
    tomorrow = Date.current + 1
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: tomorrow.in_time_zone.change(hour: 10)) }
    sign_in_owner(professional_user)
    find("[data-day='#{tomorrow.iso8601}']").click
    click_on "Ana Paula Ribeiro"
    click_button "Desmarcar este horário"
    click_button "Sim, desmarcar"
    find("turbo-frame#appointment_detail section", text: "Desmarcado")
    click_on "Voltar para a agenda"
    find("[data-day='#{Date.current.iso8601}']").click

    find("[data-day='#{tomorrow.iso8601}']").click
    find("summary", text: "desmarcado").click

    expect(page).to have_css(".line-through", text: "Ana Paula Ribeiro")
  end

  it "swaps the title on tap and reveals the row skeleton when the response is slow" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    sign_in_owner(professional_user)
    target = Date.current + 9
    held = []
    page.driver.browser.on(:request) { |request| request.url.include?("day=#{target.iso8601}") ? held << request : request.continue }
    page.driver.browser.network.intercept(pattern: "*/owner/appointments*")

    find("[data-day='#{target.iso8601}']").click

    expect(page).to have_css("#agenda_day h1", text: Components::LongDate.new(date: target).call)
    expect(page).to have_css("#agenda_day main [data-skeleton]", visible: :visible)
    expect(page).to fit_the_phone_width
    held.each(&:continue)
  end

  it "fetches again a day whose preload failed on the network" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
    tomorrow = Date.current + 1
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: create(:client, tenant: tenant, name: "Bruna Salles"), starts_at: tomorrow.in_time_zone.change(hour: 10)) }
    aborted = []
    page.driver.browser.on(:request) do |request|
      if request.url.include?("day=#{tomorrow.iso8601}") && aborted.empty?
        aborted << request
        request.abort
      else
        request.continue
      end
    end
    page.driver.browser.network.intercept(pattern: "*/owner/appointments*")
    sign_in_owner(professional_user)
    wait_until { aborted.any? }

    find("[data-day='#{tomorrow.iso8601}']").click

    expect(page).to have_text("Bruna Salles")
  end

  it "does not reuse an error response" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    sign_in_owner(professional_user)
    target = Date.current + 9
    page.driver.browser.on(:request) { |request| request.url.include?("day=#{target.iso8601}") ? request.respond(status: 500, body: "") : request.continue }
    page.driver.browser.network.intercept(pattern: "*/owner/appointments*")

    find("[data-day='#{target.iso8601}']").click
    sleep 0.2
    find("[data-day='#{target.iso8601}']").click
    sleep 0.2

    expect(page.driver.network_traffic.count { |exchange| exchange.url&.include?("day=#{target.iso8601}") }).to be >= 2
  end
end
