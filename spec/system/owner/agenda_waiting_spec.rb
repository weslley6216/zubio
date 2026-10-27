require "rails_helper"

RSpec.describe "Owner agenda skeleton", type: :system, js: true do
  it "replaces the agenda rows with a skeleton while the day loads" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9, min: 45))
    end
    sign_in_owner(professional_user)

    page.execute_script("document.getElementById('agenda_day').setAttribute('busy', '')")

    expect(page).to have_css("#agenda_day [data-skeleton]", visible: :visible)
    expect(page).to have_no_css("#agenda_day [data-appointment-id]", visible: :visible)
    expect(page).to fit_the_phone_width
  end

  it "shows the detail skeleton on desktop while the appointment loads" do
    tenant = create(:tenant, subdomain: "estudio-aurora", name: "Estúdio Aurora")
    professional_user = create(:user, :with_professional, tenant: tenant, name: "Ana Lima")
    service = create(:service, tenant: tenant, duration_minutes: 45)
    client = create(:client, tenant: tenant)
    ActsAsTenant.with_tenant(tenant) do
      create(:appointment, tenant: tenant, professional: professional_user.professional, service: service, client: client, starts_at: Date.current.in_time_zone.change(hour: 9, min: 45))
    end
    emulate_desktop_screen
    sign_in_owner(professional_user)

    page.execute_script("document.getElementById('appointment_detail').setAttribute('busy', '')")

    expect(page).to have_css("#appointment_detail [data-skeleton]", visible: :visible)
  end
end
