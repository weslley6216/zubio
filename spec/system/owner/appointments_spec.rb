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
end
