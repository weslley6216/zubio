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

    find("[data-day='#{wednesday.iso8601}']").trigger("click")

    expect(page).to have_no_link("Chamar no WhatsApp")
  end
end
