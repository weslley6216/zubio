require "rails_helper"

RSpec.describe "Owner appointments", type: :system, js: true do
  %w[light dark].each do |scheme|
    it "renders the populated agenda fitting the phone width, in #{scheme}" do
      tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
      create(:branding, tenant: tenant)
      professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
      service = create(:service, tenant: tenant, name: "Design de sobrancelhas", duration_minutes: 45)
      client = create(:client, tenant: tenant, name: "Ana Paula Ribeiro", phone: "11988771234")
      ActsAsTenant.with_tenant(tenant) do
        create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9, min: 45))
      end
      emulate_color_scheme(scheme)

      sign_in_owner(professional_user)

      expect(page).to fit_the_phone_width
      expect(page).to have_text("Ana Paula Ribeiro")
    end
  end

  it "shows four days at a time on the phone and scrolls to the fourteenth" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant)
    client = create(:client, tenant: tenant)
    last_day = Date.current + 13
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: last_day.in_time_zone.change(hour: 9)) }

    sign_in_owner(professional_user)

    expect(page.evaluate_script(<<~JS)).to eq(4)
      (() => {
        const strip = document.querySelector('[data-day-selector]').getBoundingClientRect();
        return [...document.querySelectorAll('[data-day-selector] [data-day]')]
          .filter((day) => { const box = day.getBoundingClientRect(); return box.left >= strip.left && box.right <= strip.right + 0.5; }).length;
      })()
    JS
    expect(page).to have_css("[data-day='#{last_day.iso8601}']")

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

  it "swaps only the day's list on a day tap, keeping the header and strip nodes" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant)
    tuesday_client = create(:client, tenant: tenant, name: "Ana Terça")
    wednesday_client = create(:client, tenant: tenant, name: "Bia Quarta")
    tuesday = Date.new(2026, 9, 8)
    wednesday = tuesday + 1
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: tuesday_client, starts_at: tuesday.in_time_zone.change(hour: 9))
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: wednesday_client, starts_at: wednesday.in_time_zone.change(hour: 9))
    end
    sign_in_owner(professional_user)
    page.execute_script("window.__kept = { header: document.querySelector('header'), strip: document.querySelector('[data-day-selector]') }")

    find("[data-day='#{wednesday.iso8601}']").trigger("click")

    expect(page).to have_text("Bia Quarta")
    expect(page).not_to have_text("Ana Terça")
    expect(page).to have_text(Components::LongDate.new(date: wednesday).call)
    expect(page.evaluate_script("Object.values(window.__kept).every((node) => document.contains(node))")).to be(true)
    expect(page).to have_css("[data-day='#{wednesday.iso8601}'][aria-current='date']")
    expect(page).to fit_the_phone_width
  end

  it "closes the open detail when the day changes" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant)
    tuesday_client = create(:client, tenant: tenant, name: "Ana Terça", phone: "11988771234")
    wednesday_client = create(:client, tenant: tenant, name: "Bia Quarta")
    tuesday = Date.new(2026, 9, 8)
    wednesday = tuesday + 1
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: tuesday_client, starts_at: tuesday.in_time_zone.change(hour: 9))
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: wednesday_client, starts_at: wednesday.in_time_zone.change(hour: 9))
    end
    sign_in_owner(professional_user)
    click_on "Ana Terça"
    expect(page).to have_link("Chamar no WhatsApp")

    find("[data-day='#{wednesday.iso8601}']").trigger("click")

    expect(page).to have_text("Bia Quarta")
    expect(page).to have_no_link("Chamar no WhatsApp")
  end

  it "keeps the fourteen days in a single scrolling row of seven on a 1280px desktop" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    last_day = Date.new(2026, 9, 21)
    emulate_desktop_screen

    sign_in_owner(professional_user)

    expect(page.evaluate_script(<<~JS)).to eq({ "rows" => 1, "visible" => 7, "total" => 14 })
      (() => {
        const strip = document.querySelector('[data-day-selector]').getBoundingClientRect();
        const days = [...document.querySelectorAll('[data-day-selector] [data-day]')].map((day) => day.getBoundingClientRect());
        return {
          rows: new Set(days.map((day) => Math.round(day.top))).size,
          visible: days.filter((day) => day.left >= strip.left - 0.5 && day.right <= strip.right + 0.5).length,
          total: days.length
        };
      })()
    JS

    page.execute_script("document.querySelector('[data-day-selector]').scrollLeft = 10000")
    find("[data-day='#{last_day.iso8601}']").click

    expect(page).to have_css("[data-day='#{last_day.iso8601}'][aria-current='date']")
  end

  it "shows only the forward arrow at the start of the phone day strip" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")

    sign_in_owner(professional_user)

    expect(page).to have_css("[data-day-strip-overflow-target='forward']")
    expect(page).to have_css("[data-day-strip-overflow-target='backward']", visible: :hidden)
    expect(page).to fit_the_phone_width
  end

  it "shows both arrows once the phone day strip is scrolled to the middle" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    sign_in_owner(professional_user)

    page.execute_script("const scroller = document.querySelector('[data-day-selector]'); scroller.scrollLeft = scroller.clientWidth")

    expect(page).to have_css("[data-day-strip-overflow-target='backward']")
    expect(page).to have_css("[data-day-strip-overflow-target='forward']")
  end

  it "hides the forward arrow at the end of the phone day strip" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    sign_in_owner(professional_user)

    page.execute_script("document.querySelector('[data-day-selector]').scrollLeft = 10000")

    expect(page).to have_css("[data-day-strip-overflow-target='backward']")
    expect(page).to have_css("[data-day-strip-overflow-target='forward']", visible: :hidden)
  end

  it "shows no arrows on the desktop day strip" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    emulate_desktop_screen

    sign_in_owner(professional_user)

    expect(page).to have_css("[data-day-strip-overflow-target='forward']", visible: :hidden)
    expect(page).to have_css("[data-day-strip-overflow-target='backward']", visible: :hidden)
  end

  it "still shows the forward arrow on a tablet-width strip that has not reached the week-wide breakpoint yet" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    page.driver.resize(800, 900)

    sign_in_owner(professional_user)

    expect(page).to have_css("[data-day-strip-overflow-target='forward']")
    expect(page).to have_css("[data-day-strip-overflow-target='backward']", visible: :hidden)
  end

  it "slides the strip forward on a forward-arrow tap without changing the selected day" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    today = Date.new(2026, 9, 8)
    sign_in_owner(professional_user)

    find("[data-day-strip-overflow-target='forward']").click

    expect(page).to have_css("[data-day-strip-overflow-target='backward']")
    expect(page.evaluate_script("document.querySelector('[data-day-selector]').scrollLeft")).to be > 0
    expect(page).to have_css("[data-day='#{today.iso8601}'][aria-current='date']")
    expect(page).to have_current_path(owner_appointments_path)
  end

  it "selects the fourth day when its center is tapped under the forward arrow" do
    travel_to Time.zone.local(2026, 9, 8, 7, 0)
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    create(:branding, tenant: tenant)
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant)
    fourth_day = Date.new(2026, 9, 11)
    fourth_day_client = create(:client, tenant: tenant, name: "Bia Quarta")
    ActsAsTenant.with_tenant(tenant) { create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: fourth_day_client, starts_at: fourth_day.in_time_zone.change(hour: 9)) }
    sign_in_owner(professional_user)

    find("[data-day='#{fourth_day.iso8601}']").click

    expect(page).to have_css("[data-day='#{fourth_day.iso8601}'][aria-current='date']")
    expect(page).to have_text("Bia Quarta")
  end
end
